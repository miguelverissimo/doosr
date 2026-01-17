# frozen_string_literal: true

require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true
    )
    sign_in @user

    @item = @user.items.create!(title: "Test item", item_type: :completable, state: :todo)
  end

  test "index returns notifications dropdown via turbo_stream" do
    create_sent_notification(@item)

    get notifications_path, as: :turbo_stream

    assert_response :success
    assert_match /turbo-stream.*action="append".*target="notification_bell"/, response.body
  end

  test "mark_all_read marks all notifications as read" do
    notification1 = create_sent_notification(@item)
    notification2 = create_sent_notification(@item)

    assert_nil notification1.read_at
    assert_nil notification2.read_at
    assert_equal 2, @user.unread_notifications_count

    post mark_all_read_notifications_path, as: :turbo_stream

    assert_response :success

    notification1.reload
    notification2.reload

    assert_not_nil notification1.read_at
    assert_not_nil notification2.read_at
    assert_equal "read", notification1.status
    assert_equal "read", notification2.status
  end

  test "mark_all_read returns turbo_stream updates for badge and dropdown" do
    create_sent_notification(@item)

    post mark_all_read_notifications_path, as: :turbo_stream

    assert_response :success
    assert_match /turbo-stream.*action="update".*target="notification_badge"/, response.body
    assert_match /turbo-stream.*action="replace".*target="notifications_dropdown"/, response.body
  end

  test "mark_all_read requires authentication" do
    sign_out

    post mark_all_read_notifications_path, as: :turbo_stream

    assert_response :redirect
  end

  test "show marks notification as read and redirects to day with highlight param" do
    day = @user.days.create!(date: Date.current)
    day.descendant.add_active_item(@item.id)
    day.descendant.save!
    notification = create_sent_notification(@item)

    assert_nil notification.read_at

    get notification_path(notification)

    assert_response :redirect
    assert_redirected_to day_path(date: day.date, highlight: @item.id)

    notification.reload
    assert_not_nil notification.read_at
    assert_equal "read", notification.status
  end

  test "show redirects to root when item has no containing day" do
    notification = create_sent_notification(@item)

    get notification_path(notification)

    assert_response :redirect
    assert_redirected_to authenticated_root_path
  end

  test "show requires authentication" do
    sign_out
    notification = create_sent_notification(@item)

    get notification_path(notification)

    assert_response :redirect
  end

  test "show cannot access notifications belonging to other users" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true
    )
    other_item = other_user.items.create!(title: "Other item", item_type: :completable, state: :todo)
    other_notification = other_user.notifications.create!(item: other_item, remind_at: 1.hour.from_now)
    other_notification.mark_sent!

    get notification_path(other_notification)

    assert_response :not_found
  end

  test "destroy deletes a reminder notification" do
    notification = @user.notifications.create!(item: @item, remind_at: 1.hour.from_now)

    assert_difference "Notification.count", -1 do
      delete notification_path(notification), as: :turbo_stream
    end

    assert_response :success
  end

  test "destroy returns turbo_stream with updated reminders section" do
    day = @user.days.create!(date: Date.current)
    day.descendant.add_active_item(@item.id)
    day.descendant.save!
    notification = @user.notifications.create!(item: @item, remind_at: 1.hour.from_now)

    delete notification_path(notification, day_id: day.id), as: :turbo_stream

    assert_response :success
    assert_match(/turbo-stream.*action="replace".*target="sheet_content_area"/, response.body)
    assert_match(/Reminder deleted/, response.body)
  end

  test "destroy updates item indicator when day is provided" do
    day = @user.days.create!(date: Date.current)
    day.descendant.add_active_item(@item.id)
    day.descendant.save!
    notification = @user.notifications.create!(item: @item, remind_at: 1.hour.from_now)

    delete notification_path(notification, day_id: day.id), as: :turbo_stream

    assert_response :success
    assert_match(/turbo-stream.*action="replace".*target="item_#{@item.id}"/, response.body)
  end

  test "destroy requires authentication" do
    sign_out
    notification = @user.notifications.create!(item: @item, remind_at: 1.hour.from_now)

    delete notification_path(notification), as: :turbo_stream

    assert_response :redirect
  end

  test "destroy cannot delete notifications belonging to other users" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true
    )
    other_item = other_user.items.create!(title: "Other item", item_type: :completable, state: :todo)
    other_notification = other_user.notifications.create!(item: other_item, remind_at: 1.hour.from_now)

    assert_no_difference "Notification.count" do
      delete notification_path(other_notification), as: :turbo_stream
    end

    assert_response :not_found
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end

  def sign_out
    delete destroy_user_session_path
  end

  def create_sent_notification(item)
    notification = @user.notifications.create!(
      item: item,
      remind_at: 1.hour.from_now
    )
    notification.mark_sent!
    notification
  end
end
