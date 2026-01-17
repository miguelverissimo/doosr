# frozen_string_literal: true

require "test_helper"

class NotificationChannelTest < ActionCable::Channel::TestCase
  def setup
    @user = User.create!(
      email: "test-channel@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def teardown
    @user.destroy!
  end

  test "subscribes when user is authenticated" do
    stub_connection(current_user: @user)

    subscribe

    assert subscription.confirmed?
    assert_has_stream "notifications:#{@user.id}"
  end

  test "rejects subscription when user is not authenticated" do
    stub_connection(current_user: nil)

    subscribe

    assert subscription.rejected?
  end
end
