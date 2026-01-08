# frozen_string_literal: true

module Journals
  class ScheduleCalculator
    def self.call(schedule_rule, date)
      new(schedule_rule, date).call
    end

    def initialize(schedule_rule, date)
      @schedule_rule = schedule_rule.is_a?(String) ? JSON.parse(schedule_rule) : schedule_rule
      @date = date.is_a?(Date) ? date : Date.parse(date.to_s)
    rescue JSON::ParserError
      @schedule_rule = {}
      @date = date
    end

    def call
      return false if @schedule_rule.blank?

      frequency = @schedule_rule["frequency"]
      return false if frequency.blank?

      case frequency
      when "daily"
        true
      when "weekly_start"
        @date.sunday?
      when "weekly_end"
        @date.saturday?
      when "monthly_start"
        @date == @date.beginning_of_month
      when "monthly_end"
        @date == @date.end_of_month
      when "day_of_month"
        day_of_month = @schedule_rule["day_of_month"]
        return false if day_of_month.blank?
        @date.day == day_of_month.to_i
      when "every_n_days"
        # This would require tracking the last occurrence date
        # For now, return false - needs implementation with state tracking
        false
      when "specific_weekdays"
        days_of_week = @schedule_rule["days_of_week"]
        return false if days_of_week.blank? || !days_of_week.is_a?(Array)
        days_of_week.include?(@date.wday)
      else
        false
      end
    end
  end
end
