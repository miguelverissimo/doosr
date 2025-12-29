# frozen_string_literal: true

module Items
  # Service to calculate the next recurrence date based on a recurrence rule
  # Supports: daily, every_weekday, every_n_days, weekly, monthly, yearly
  class RecurrenceCalculator
    def initialize(recurrence_rule:, from_date:)
      @recurrence_rule = parse_rule(recurrence_rule)
      @from_date = from_date.to_date
    end

    def call
      return nil unless @recurrence_rule

      case @recurrence_rule["frequency"]
      when "daily"
        calculate_daily
      when "every_weekday"
        calculate_every_weekday
      when "every_n_days"
        calculate_every_n_days
      when "weekly"
        calculate_weekly
      when "monthly"
        calculate_monthly
      when "yearly"
        calculate_yearly
      else
        nil
      end
    end

    private

    def parse_rule(rule)
      return nil if rule.nil?
      return rule if rule.is_a?(Hash)

      # If it's a string, try to parse as JSON
      JSON.parse(rule)
    rescue JSON::ParserError
      nil
    end

    # Daily: next day
    def calculate_daily
      (@from_date + 1.day).beginning_of_day
    end

    # Every weekday: next weekday (Monday-Friday)
    def calculate_every_weekday
      next_date = @from_date + 1.day
      # Skip to next Monday if we land on a weekend
      while next_date.wday == 0 || next_date.wday == 6 # Sunday = 0, Saturday = 6
        next_date += 1.day
      end
      next_date.beginning_of_day
    end

    # Every N days: add interval days
    def calculate_every_n_days
      interval = @recurrence_rule["interval"].to_i
      return nil if interval <= 0

      (@from_date + interval.days).beginning_of_day
    end

    # Weekly: next occurrence on specified days of week
    # days_of_week is an array of integers: 0=Sunday, 1=Monday, ..., 6=Saturday
    def calculate_weekly
      days_of_week = @recurrence_rule["days_of_week"]
      return nil unless days_of_week.is_a?(Array) && days_of_week.any?

      # Sort and ensure valid day numbers (0-6)
      valid_days = days_of_week.map(&:to_i).select { |d| d >= 0 && d <= 6 }.sort

      return nil if valid_days.empty?

      # Find the next occurrence
      next_date = @from_date + 1.day
      # Search up to 7 days ahead to find the next matching day
      7.times do
        return next_date.beginning_of_day if valid_days.include?(next_date.wday)
        next_date += 1.day
      end

      nil # Should never reach here if valid_days is not empty
    end

    # Monthly: same day next month (rolling/clamping for shorter months)
    def calculate_monthly
      target_day = @from_date.day
      next_month = @from_date.next_month

      # Handle months with fewer days (e.g., Jan 31 -> Feb 28/29)
      if target_day > next_month.end_of_month.day
        next_month.end_of_month.beginning_of_day
      else
        next_month.change(day: target_day).beginning_of_day
      end
    end

    # Yearly: same date next year
    def calculate_yearly
      (@from_date.next_year).beginning_of_day
    rescue ArgumentError
      # Handle Feb 29 on non-leap years
      (@from_date.next_year.change(day: 28)).beginning_of_day
    end
  end
end
