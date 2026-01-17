# frozen_string_literal: true

require "test_helper"

class SendNotificationJobTest < ActiveSupport::TestCase
  include ActionCable::TestHelper
  def setup
    @user = User.create!(
      email: "test-send-notification@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @item = Item.create!(
      user: @user,
      title: "Test item",
      item_type: :completable
    )
  end

  def teardown
    @user.destroy!
  end

  test "processes due pending notifications" do
    notification = Notification.create!(
      user: @user,
      item: @item,
      remind_at: 1.hour.from_now,
      title: "Test reminder",
      channels: [ "in_app" ]
    )
    notification.update_column(:remind_at, 1.minute.ago)

    SendNotificationJob.perform_now

    notification.reload
    assert_equal "sent", notification.status
    assert_not_nil notification.sent_at
  end

  test "does not process future notifications" do
    notification = Notification.create!(
      user: @user,
      item: @item,
      remind_at: 1.hour.from_now,
      title: "Future reminder",
      channels: [ "in_app" ]
    )

    SendNotificationJob.perform_now

    notification.reload
    assert_equal "pending", notification.status
    assert_nil notification.sent_at
  end

  test "skips notifications during quiet hours" do
    current_hour = Time.current.strftime("%H").to_i
    quiet_start = format("%02d:00", (current_hour - 1) % 24)
    quiet_end = format("%02d:00", (current_hour + 1) % 24)

    @user.update!(notification_preferences: {
      "push_enabled" => true,
      "in_app_enabled" => true,
      "quiet_hours_start" => quiet_start,
      "quiet_hours_end" => quiet_end
    })

    notification = Notification.create!(
      user: @user,
      item: @item,
      remind_at: 1.hour.from_now,
      title: "Test reminder",
      channels: [ "in_app" ]
    )
    notification.update_column(:remind_at, 1.minute.ago)

    SendNotificationJob.perform_now

    notification.reload
    assert_equal "pending", notification.status
  end

  test "is idempotent - does not resend already sent notifications" do
    notification = Notification.create!(
      user: @user,
      item: @item,
      remind_at: 1.hour.from_now,
      title: "Already sent",
      channels: [ "in_app" ]
    )
    notification.update_column(:remind_at, 1.minute.ago)
    notification.mark_sent!
    original_sent_at = notification.sent_at

    SendNotificationJob.perform_now

    notification.reload
    assert_equal "sent", notification.status
    assert_equal original_sent_at.to_i, notification.sent_at.to_i
  end

  test "handles in_app channel without push subscriptions" do
    notification = Notification.create!(
      user: @user,
      item: @item,
      remind_at: 1.hour.from_now,
      title: "In-app only",
      channels: [ "in_app" ]
    )
    notification.update_column(:remind_at, 1.minute.ago)

    SendNotificationJob.perform_now

    notification.reload
    assert_equal "sent", notification.status
  end

  test "handles multiple due notifications" do
    notifications = 3.times.map do |i|
      n = Notification.create!(
        user: @user,
        item: @item,
        remind_at: 1.hour.from_now,
        title: "Reminder #{i}",
        channels: [ "in_app" ]
      )
      n.update_column(:remind_at, 1.minute.ago)
      n
    end

    SendNotificationJob.perform_now

    notifications.each do |n|
      n.reload
      assert_equal "sent", n.status
    end
  end

  test "gracefully handles errors without crashing" do
    assert_nothing_raised do
      SendNotificationJob.perform_now
    end
  end

  test "broadcasts badge update to user's notification channel after sending" do
    notification = Notification.create!(
      user: @user,
      item: @item,
      remind_at: 1.hour.from_now,
      title: "Test reminder",
      channels: [ "in_app" ]
    )
    notification.update_column(:remind_at, 1.minute.ago)

    assert_broadcasts("notifications:#{@user.id}", 1) do
      SendNotificationJob.perform_now
    end
  end
end
