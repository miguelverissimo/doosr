# frozen_string_literal: true

require "test_helper"

class ItemNotificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true
    )
    sign_in @user

    @item = @user.items.create!(title: "Test item", item_type: :completable, state: :todo)
    @day = @user.days.create!(date: Date.current)
    @day.descendant.add_active_item(@item.id)
    @day.descendant.save!
  end

  test "create creates a reminder notification for an item" do
    reminder_time = 1.hour.from_now

    assert_difference "@item.notifications.count", 1 do
      post item_notifications_path(@item), params: {
        remind_at: reminder_time.strftime("%Y-%m-%dT%H:%M"),
        day_id: @day.id
      }, as: :turbo_stream
    end

    assert_response :success

    notification = @item.notifications.last
    assert_equal "pending", notification.status
    assert_equal @user.id, notification.user_id
    assert_in_delta reminder_time.to_i, notification.remind_at.to_i, 60
  end

  test "create returns turbo_stream with updated reminders section" do
    reminder_time = 1.hour.from_now

    post item_notifications_path(@item), params: {
      remind_at: reminder_time.strftime("%Y-%m-%dT%H:%M"),
      day_id: @day.id
    }, as: :turbo_stream

    assert_response :success
    assert_match(/turbo-stream.*action="replace".*target="sheet_content_area"/, response.body)
    assert_match(/Reminder added/, response.body)
  end

  test "create returns turbo_stream with updated item when day provided" do
    reminder_time = 1.hour.from_now

    post item_notifications_path(@item), params: {
      remind_at: reminder_time.strftime("%Y-%m-%dT%H:%M"),
      day_id: @day.id
    }, as: :turbo_stream

    assert_response :success
    assert_match(/turbo-stream.*action="replace".*target="item_#{@item.id}"/, response.body)
  end

  test "create validates remind_at is in the future" do
    past_time = 1.hour.ago

    assert_no_difference "@item.notifications.count" do
      post item_notifications_path(@item), params: {
        remind_at: past_time.strftime("%Y-%m-%dT%H:%M"),
        day_id: @day.id
      }, as: :turbo_stream
    end

    assert_response :success
    assert_match(/must be in the future/, response.body)
  end

  test "create requires authentication" do
    sign_out

    post item_notifications_path(@item), params: {
      remind_at: 1.hour.from_now.strftime("%Y-%m-%dT%H:%M")
    }, as: :turbo_stream

    assert_response :redirect
  end

  test "create cannot create notifications for other users items" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true
    )
    other_item = other_user.items.create!(title: "Other item", item_type: :completable, state: :todo)

    assert_no_difference "Notification.count" do
      post item_notifications_path(other_item), params: {
        remind_at: 1.hour.from_now.strftime("%Y-%m-%dT%H:%M")
      }, as: :turbo_stream
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
end
