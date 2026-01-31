require "test_helper"

class Days::ReopenServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "reopenservice@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES
    )
    @day = @user.days.create!(date: Date.today, state: :closed, closed_at: Time.current, skip_permanent_sections_callback: true)
  end

  test "reopens a closed day" do
    result = Days::ReopenService.new(day: @day).call

    assert result[:success]
    assert_equal @day, result[:day]
    @day.reload
    assert @day.open?
    assert_not_nil @day.reopened_at
  end

  test "clears closed_at when reopening" do
    assert_not_nil @day.closed_at

    Days::ReopenService.new(day: @day).call
    @day.reload
    assert_nil @day.closed_at
  end

  test "returns success hash" do
    result = Days::ReopenService.new(day: @day).call

    assert result.key?(:success)
    assert result.key?(:day)
  end
end
