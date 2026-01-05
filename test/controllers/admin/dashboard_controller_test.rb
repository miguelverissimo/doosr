# frozen_string_literal: true

require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: [ "admin" ]
    )
    sign_in @user
  end

  test "should get index" do
    get admin_root_path
    assert_response :success
  end

  test "should redirect to sign in when not authenticated" do
    sign_out @user
    get admin_root_path
    assert_redirected_to new_user_session_path
  end

  test "should render dashboard view" do
    get admin_root_path
    assert_response :success
    assert_match /Admin Dashboard/, response.body
  end

  test "should show navigation cards" do
    get admin_root_path
    assert_response :success
    assert_match /User Management/, response.body
    assert_match /Notifications/, response.body
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end

  def sign_out(user)
    delete destroy_user_session_path
  end
end
