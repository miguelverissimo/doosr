# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true
    )
    sign_in @user
  end

  test "update_notification_preferences saves preferences" do
    patch update_notification_preferences_settings_path, params: {
      notification_preferences: {
        push_enabled: "true",
        in_app_enabled: "false",
        quiet_hours_start: "22:00",
        quiet_hours_end: "08:00"
      }
    }, as: :turbo_stream

    assert_response :success
    @user.reload

    assert_equal true, @user.notification_preferences["push_enabled"]
    assert_equal false, @user.notification_preferences["in_app_enabled"]
    assert_equal "22:00", @user.notification_preferences["quiet_hours_start"]
    assert_equal "08:00", @user.notification_preferences["quiet_hours_end"]
  end

  test "update_notification_preferences returns success toast" do
    patch update_notification_preferences_settings_path, params: {
      notification_preferences: {
        push_enabled: "true",
        in_app_enabled: "true"
      }
    }, as: :turbo_stream

    assert_response :success
    assert_match(/Notification preferences saved/, response.body)
  end

  test "update_notification_preferences handles empty quiet hours" do
    patch update_notification_preferences_settings_path, params: {
      notification_preferences: {
        push_enabled: "true",
        in_app_enabled: "true",
        quiet_hours_start: "",
        quiet_hours_end: ""
      }
    }, as: :turbo_stream

    assert_response :success
    @user.reload

    assert_nil @user.notification_preferences["quiet_hours_start"]
    assert_nil @user.notification_preferences["quiet_hours_end"]
  end

  test "update_notification_preferences requires authentication" do
    sign_out

    patch update_notification_preferences_settings_path, params: {
      notification_preferences: { push_enabled: "true" }
    }, as: :turbo_stream

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "update_notification_preferences returns json format" do
    patch update_notification_preferences_settings_path, params: {
      notification_preferences: {
        push_enabled: "false",
        in_app_enabled: "true",
        quiet_hours_start: "23:00",
        quiet_hours_end: "07:00"
      }
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal false, json["notification_preferences"]["push_enabled"]
    assert_equal true, json["notification_preferences"]["in_app_enabled"]
    assert_equal "23:00", json["notification_preferences"]["quiet_hours_start"]
    assert_equal "07:00", json["notification_preferences"]["quiet_hours_end"]
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
