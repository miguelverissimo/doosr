# frozen_string_literal: true

require "test_helper"

class Notifications::WebPushDeliveryServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test-webpush@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true
    )
    @day = @user.days.create!(date: Date.today, state: :open)
    @item = @user.items.create!(
      title: "Test Item",
      item_type: :completable,
      state: :todo
    )
    @day.descendant.add_active_item(@item.id)
    @day.descendant.save!

    @notification = @user.notifications.create!(
      item: @item,
      remind_at: 1.hour.from_now,
      title: "Test Notification",
      body: "Test body message",
      status: "pending"
    )
  end

  test "returns error when push is disabled for user" do
    @user.update!(notification_preferences: { "push_enabled" => false })

    service = Notifications::WebPushDeliveryService.new(@notification)
    result = service.deliver

    assert_not result[:success]
    assert_equal "Push notifications disabled for user", result[:error]
  end

  test "returns error when no active subscriptions" do
    service = Notifications::WebPushDeliveryService.new(@notification)
    result = service.deliver

    assert_not result[:success]
    assert_equal "No active subscriptions found", result[:error]
  end

  test "builds payload with title and body from notification" do
    service = Notifications::WebPushDeliveryService.new(@notification)

    payload = service.send(:build_payload)

    assert_equal "Test Notification", payload[:title]
    assert_equal "Test body message", payload[:options][:body]
    assert_equal @notification.id, payload[:options][:data][:notification_id]
    assert_equal @item.id, payload[:options][:data][:item_id]
  end

  test "builds payload with item title when notification title is nil" do
    @notification.update!(title: nil)

    service = Notifications::WebPushDeliveryService.new(@notification)
    payload = service.send(:build_payload)

    assert_equal @item.title, payload[:title]
  end

  test "builds click action URL pointing to the day containing the item" do
    service = Notifications::WebPushDeliveryService.new(@notification)
    path = service.send(:find_item_day_path)

    assert_equal "/days/#{@day.date.iso8601}", path
  end

  test "builds click action URL pointing to root when item is nested" do
    parent_item = @user.items.create!(
      title: "Parent Item",
      item_type: :completable,
      state: :todo
    )
    @day.descendant.add_active_item(parent_item.id)
    @day.descendant.save!

    parent_item.create_descendant!(active_items: [], inactive_items: [])
    parent_item.descendant.add_active_item(@item.id)
    parent_item.descendant.save!

    @day.descendant.remove_active_item(@item.id)
    @day.descendant.save!

    service = Notifications::WebPushDeliveryService.new(@notification)
    path = service.send(:find_item_day_path)

    assert_equal "/days/#{@day.date.iso8601}", path
  end

  test "returns root path when item is not found in any day" do
    @day.descendant.remove_active_item(@item.id)
    @day.descendant.save!

    service = Notifications::WebPushDeliveryService.new(@notification)
    path = service.send(:find_item_day_path)

    assert_equal "/", path
  end

  test "respects user push_enabled preference (enabled by default)" do
    service = Notifications::WebPushDeliveryService.new(@notification)
    assert service.send(:push_enabled?)
  end

  test "respects user push_enabled preference when explicitly set" do
    @user.update!(notification_preferences: { "push_enabled" => true })

    service = Notifications::WebPushDeliveryService.new(@notification)
    assert service.send(:push_enabled?)
  end

  test "payload includes icon and badge from base URL" do
    service = Notifications::WebPushDeliveryService.new(@notification)
    payload = service.send(:build_payload)

    assert payload[:options][:icon].include?("/web-app-manifest-192x192.png")
    assert payload[:options][:badge].include?("/web-app-manifest-192x192.png")
  end

  test "payload includes tag for notification deduplication" do
    service = Notifications::WebPushDeliveryService.new(@notification)
    payload = service.send(:build_payload)

    assert_equal "notification-#{@notification.id}", payload[:options][:tag]
  end
end
