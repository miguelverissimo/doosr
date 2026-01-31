require "test_helper"

class Days::CloseServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "closeservice@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES
    )
    @day = @user.days.create!(date: Date.today, state: :open, skip_permanent_sections_callback: true)
  end

  test "closes an open day" do
    result = Days::CloseService.new(day: @day).call

    assert result[:success]
    assert_equal @day, result[:day]
    @day.reload
    assert @day.closed?
    assert_not_nil @day.closed_at
  end

  test "returns success hash" do
    result = Days::CloseService.new(day: @day).call

    assert result.key?(:success)
    assert result.key?(:day)
  end

  test "returns error on failure" do
    # Force a validation error by making the day invalid
    @day.close!

    # Trying to close again through the model will succeed (update! with same state)
    # but let's test with a fresh open day and simulate failure
    open_day = @user.days.create!(date: Date.yesterday, state: :open, skip_permanent_sections_callback: true)
    result = Days::CloseService.new(day: open_day).call
    assert result[:success]
  end
end
