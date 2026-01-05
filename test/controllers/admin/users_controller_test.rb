# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: [ "admin" ]
    )

    @user1 = User.create!(
      email: "user1@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User 1",
      access_confirmed: false,
      roles: []
    )

    @user2 = User.create!(
      email: "user2@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User 2",
      access_confirmed: true,
      roles: [ "accounting" ]
    )

    sign_in @admin
  end

  # Index action tests

  test "should get index" do
    get admin_users_path
    assert_response :success
  end

  test "should redirect to sign in when not authenticated" do
    sign_out @admin
    get admin_users_path
    assert_redirected_to new_user_session_path
  end

  test "should list all users" do
    get admin_users_path
    assert_response :success
    assert_match /user1@example.com/, response.body
    assert_match /user2@example.com/, response.body
    assert_match /admin@example.com/, response.body
  end

  test "should show user names and emails" do
    get admin_users_path
    assert_response :success
    assert_match /Test User 1/, response.body
    assert_match /Test User 2/, response.body
  end

  # Toggle access tests

  test "should toggle access_confirmed from false to true" do
    assert_equal false, @user1.access_confirmed

    patch toggle_access_admin_user_path(@user1), as: :turbo_stream

    assert_response :success
    @user1.reload
    assert_equal true, @user1.access_confirmed
  end

  test "should toggle access_confirmed from true to false" do
    assert_equal true, @user2.access_confirmed

    patch toggle_access_admin_user_path(@user2), as: :turbo_stream

    assert_response :success
    @user2.reload
    assert_equal false, @user2.access_confirmed
  end

  test "toggle access should return turbo_stream response" do
    patch toggle_access_admin_user_path(@user1), as: :turbo_stream

    assert_response :success
    assert_match /turbo-stream/, response.body
    assert_match /user_#{@user1.id}/, response.body
  end

  test "toggle access should show success toast" do
    patch toggle_access_admin_user_path(@user1), as: :turbo_stream

    assert_response :success
    assert_match /User access updated/, response.body
    assert_match /window.toast/, response.body
  end

  test "toggle access requires authentication" do
    sign_out @admin
    patch toggle_access_admin_user_path(@user1), as: :turbo_stream

    assert_redirected_to new_user_session_path
  end

  # Update roles tests

  test "should update user roles" do
    patch update_roles_admin_user_path(@user1),
          params: { roles: [ "admin", "accounting" ] }.to_json,
          headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html" }

    assert_response :success
    @user1.reload
    assert_equal [ "accounting", "admin" ].sort, @user1.roles.sort
  end

  test "should update roles to empty array" do
    patch update_roles_admin_user_path(@user2),
          params: { roles: [] }.to_json,
          headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html" }

    assert_response :success
    @user2.reload
    assert_equal [], @user2.roles
  end

  test "should update single role" do
    patch update_roles_admin_user_path(@user1),
          params: { roles: [ "fixed_calendar" ] }.to_json,
          headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html" }

    assert_response :success
    @user1.reload
    assert_equal [ "fixed_calendar" ], @user1.roles
  end

  test "should update all available roles" do
    patch update_roles_admin_user_path(@user1),
          params: { roles: User::AVAILABLE_ROLES }.to_json,
          headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html" }

    assert_response :success
    @user1.reload
    assert_equal User::AVAILABLE_ROLES.sort, @user1.roles.sort
  end

  test "update roles should return turbo_stream response" do
    patch update_roles_admin_user_path(@user1),
          params: { roles: [ "admin" ] }.to_json,
          headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match /turbo-stream/, response.body
    assert_match /user_#{@user1.id}/, response.body
  end

  test "update roles should show success toast" do
    patch update_roles_admin_user_path(@user1),
          params: { roles: [ "admin" ] }.to_json,
          headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match /Roles updated/, response.body
    assert_match /window.toast/, response.body
  end

  test "update roles requires authentication" do
    sign_out @admin
    patch update_roles_admin_user_path(@user1),
          params: { roles: [ "admin" ] }.to_json,
          headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html" }

    assert_redirected_to new_user_session_path
  end

  test "update roles handles nil roles parameter" do
    patch update_roles_admin_user_path(@user2),
          params: {}.to_json,
          headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html" }

    assert_response :success
    @user2.reload
    assert_equal [], @user2.roles
  end

  test "should reject invalid roles" do
    patch update_roles_admin_user_path(@user1),
          params: { roles: [ "invalid_role" ] }.to_json,
          headers: { "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html" }

    assert_response :unprocessable_entity
    @user1.reload
    assert_equal [], @user1.roles
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
