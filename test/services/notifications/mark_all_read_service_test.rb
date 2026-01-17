# frozen_string_literal: true

require "test_helper"

class Notifications::MarkAllReadServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test-markread@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true
    )
    @item = @user.items.create!(
      title: "Test Item",
      item_type: :completable,
      state: :todo
    )
  end

  test "marks all unread notifications as read" do
    notification1 = create_sent_notification
    notification2 = create_sent_notification

    service = Notifications::MarkAllReadService.new(@user)
    result = service.call

    assert result[:success]
    assert_equal 2, result[:count]

    notification1.reload
    notification2.reload
    assert_equal "read", notification1.status
    assert_equal "read", notification2.status
    assert_not_nil notification1.read_at
    assert_not_nil notification2.read_at
  end

  test "returns zero count when no unread notifications" do
    service = Notifications::MarkAllReadService.new(@user)
    result = service.call

    assert result[:success]
    assert_equal 0, result[:count]
  end

  test "does not affect pending notifications" do
    pending_notification = @user.notifications.create!(
      item: @item,
      remind_at: 1.hour.from_now,
      status: "pending"
    )

    service = Notifications::MarkAllReadService.new(@user)
    result = service.call

    assert result[:success]
    assert_equal 0, result[:count]

    pending_notification.reload
    assert_equal "pending", pending_notification.status
  end

  test "does not affect already read notifications" do
    notification = create_sent_notification
    notification.mark_read!
    original_read_at = notification.read_at

    service = Notifications::MarkAllReadService.new(@user)
    result = service.call

    assert_equal 0, result[:count]

    notification.reload
    assert_equal original_read_at.to_i, notification.read_at.to_i
  end

  test "does not affect other users notifications" do
    other_user = User.create!(
      email: "other-user@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true
    )
    other_item = other_user.items.create!(
      title: "Other Item",
      item_type: :completable,
      state: :todo
    )
    other_notification = other_user.notifications.create!(
      item: other_item,
      remind_at: 1.hour.from_now,
      status: "pending"
    )
    other_notification.update_column(:status, "sent")

    service = Notifications::MarkAllReadService.new(@user)
    result = service.call

    assert_equal 0, result[:count]

    other_notification.reload
    assert_equal "sent", other_notification.status
  end

  private

  def create_sent_notification
    notification = @user.notifications.create!(
      item: @item,
      remind_at: 1.hour.from_now,
      status: "pending"
    )
    notification.update_column(:status, "sent")
    notification.update_column(:sent_at, 1.minute.ago)
    notification
  end
end
