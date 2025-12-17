# frozen_string_literal: true

require "test_helper"

module Items
  class RecurrenceCalculatorTest < ActiveSupport::TestCase
    test "daily recurrence calculates next day" do
      from_date = Date.new(2025, 1, 15)
      rule = { "frequency" => "daily" }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 1, 16).beginning_of_day, next_date
    end

    test "every_weekday calculates next weekday from Monday" do
      from_date = Date.new(2025, 1, 13) # Monday
      rule = { "frequency" => "every_weekday" }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 1, 14).beginning_of_day, next_date # Tuesday
    end

    test "every_weekday skips weekend to Monday" do
      from_date = Date.new(2025, 1, 17) # Friday
      rule = { "frequency" => "every_weekday" }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 1, 20).beginning_of_day, next_date # Next Monday
    end

    test "every_weekday skips Sunday to Monday" do
      from_date = Date.new(2025, 1, 19) # Sunday
      rule = { "frequency" => "every_weekday" }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 1, 20).beginning_of_day, next_date # Monday
    end

    test "every_n_days calculates with interval 3" do
      from_date = Date.new(2025, 1, 15)
      rule = { "frequency" => "every_n_days", "interval" => 3 }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 1, 18).beginning_of_day, next_date
    end

    test "every_n_days calculates with interval 7" do
      from_date = Date.new(2025, 1, 15)
      rule = { "frequency" => "every_n_days", "interval" => 7 }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 1, 22).beginning_of_day, next_date
    end

    test "weekly with Monday and Friday from Wednesday" do
      from_date = Date.new(2025, 1, 15) # Wednesday
      rule = { "frequency" => "weekly", "days_of_week" => [1, 5] } # Mon, Fri

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 1, 17).beginning_of_day, next_date # Friday
    end

    test "weekly with Monday and Friday from Friday" do
      from_date = Date.new(2025, 1, 17) # Friday
      rule = { "frequency" => "weekly", "days_of_week" => [1, 5] } # Mon, Fri

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 1, 20).beginning_of_day, next_date # Monday
    end

    test "weekly with Sunday" do
      from_date = Date.new(2025, 1, 17) # Friday
      rule = { "frequency" => "weekly", "days_of_week" => [0] } # Sunday

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 1, 19).beginning_of_day, next_date # Sunday
    end

    test "weekly with all weekdays" do
      from_date = Date.new(2025, 1, 15) # Wednesday
      rule = { "frequency" => "weekly", "days_of_week" => [1, 2, 3, 4, 5] } # Mon-Fri

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 1, 16).beginning_of_day, next_date # Thursday
    end

    test "monthly from mid-month" do
      from_date = Date.new(2025, 1, 15)
      rule = { "frequency" => "monthly" }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 2, 15).beginning_of_day, next_date
    end

    test "monthly from Jan 31 to Feb 28" do
      from_date = Date.new(2025, 1, 31)
      rule = { "frequency" => "monthly" }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      # February 2025 has 28 days, so it should clamp to Feb 28
      assert_equal Date.new(2025, 2, 28).beginning_of_day, next_date
    end

    test "monthly from Jan 31 to March 31" do
      from_date = Date.new(2025, 1, 31)
      rule = { "frequency" => "monthly" }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      # First call: Jan 31 -> Feb 28
      assert_equal Date.new(2025, 2, 28).beginning_of_day, next_date

      # Second call: Feb 28 -> Mar 28 (not Mar 31, because from_date is Feb 28)
      calculator2 = RecurrenceCalculator.new(recurrence_rule: rule, from_date: next_date.to_date)
      next_date2 = calculator2.call
      assert_equal Date.new(2025, 3, 28).beginning_of_day, next_date2
    end

    test "yearly recurrence" do
      from_date = Date.new(2025, 1, 15)
      rule = { "frequency" => "yearly" }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2026, 1, 15).beginning_of_day, next_date
    end

    test "yearly from Feb 29 on leap year to non-leap year" do
      from_date = Date.new(2024, 2, 29) # Leap year
      rule = { "frequency" => "yearly" }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      # Should clamp to Feb 28 since 2025 is not a leap year
      assert_equal Date.new(2025, 2, 28).beginning_of_day, next_date
    end

    test "returns nil for invalid frequency" do
      from_date = Date.new(2025, 1, 15)
      rule = { "frequency" => "invalid" }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_nil next_date
    end

    test "returns nil for nil rule" do
      from_date = Date.new(2025, 1, 15)

      calculator = RecurrenceCalculator.new(recurrence_rule: nil, from_date: from_date)
      next_date = calculator.call

      assert_nil next_date
    end

    test "parses JSON string rule" do
      from_date = Date.new(2025, 1, 15)
      rule_string = '{"frequency":"daily"}'

      calculator = RecurrenceCalculator.new(recurrence_rule: rule_string, from_date: from_date)
      next_date = calculator.call

      assert_equal Date.new(2025, 1, 16).beginning_of_day, next_date
    end

    test "returns nil for invalid JSON" do
      from_date = Date.new(2025, 1, 15)
      rule_string = "not valid json"

      calculator = RecurrenceCalculator.new(recurrence_rule: rule_string, from_date: from_date)
      next_date = calculator.call

      assert_nil next_date
    end

    test "every_n_days returns nil for invalid interval" do
      from_date = Date.new(2025, 1, 15)
      rule = { "frequency" => "every_n_days", "interval" => 0 }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_nil next_date
    end

    test "weekly returns nil for empty days_of_week" do
      from_date = Date.new(2025, 1, 15)
      rule = { "frequency" => "weekly", "days_of_week" => [] }

      calculator = RecurrenceCalculator.new(recurrence_rule: rule, from_date: from_date)
      next_date = calculator.call

      assert_nil next_date
    end
  end
end
