# frozen_string_literal: true

module FixedCalendar
  class Converter
    MONTHS = [
      "Martius", "Aprilis", "Maius", "Iunius", "Sol", "Iulius", "Augustus",
      "September", "October", "November", "December", "Undecember", "Duodecember"
    ].freeze

    DAY_NAMES = [
      "dies Solis",     # Sunday
      "dies Lunae",     # Monday
      "dies Martis",    # Tuesday
      "dies Mercurii",  # Wednesday
      "dies Iovis",     # Thursday
      "dies Veneris",   # Friday
      "dies Saturni"    # Saturday
    ].freeze

    DAYS_PER_MONTH = 28

    def initialize(target_date = Date.current)
      @target_date = target_date
    end

    def to_equinox_calendar
      year = @target_date.year
      # Define start as March 20 of the current (or previous) year
      start_date = Date.new(year, 3, 20)

      # If today is before March 20, we are still in the previous year's cycle
      start_date = Date.new(year - 1, 3, 20) if @target_date < start_date

      days_since_start = (@target_date - start_date).to_i + 1
      is_leap = Date.leap?(start_date.year)

      # Leap Day comes after Junius 28 (day 168 = 6 months * 28 days)
      # So day 169 in a leap year is Leap Day
      if is_leap && days_since_start == 169
        return {
          type: :leap_day,
          display: "Leap Day",
          month_index: nil,
          day: nil,
          year_cycle_start: start_date,
          cycle_year: start_date.year
        }
      end

      # Year Day is the last day: day 365 in non-leap, day 366 in leap
      year_day_number = is_leap ? 366 : 365
      if days_since_start == year_day_number
        return {
          type: :year_day,
          display: "Year Day",
          month_index: nil,
          day: nil,
          year_cycle_start: start_date,
          cycle_year: start_date.year
        }
      end

      # Adjust for leap day: if we're past day 169 in a leap year, subtract 1
      adjusted_day = (is_leap && days_since_start > 169) ? days_since_start - 1 : days_since_start

      month_idx = (adjusted_day - 1) / DAYS_PER_MONTH
      day_of_month = (adjusted_day - 1) % DAYS_PER_MONTH + 1

      {
        type: :regular,
        display: "#{MONTHS[month_idx]} #{day_of_month}",
        month_name: MONTHS[month_idx],
        month_index: month_idx,
        day: day_of_month,
        year_cycle_start: start_date,
        cycle_year: start_date.year
      }
    end

    def self.month_name(index)
      MONTHS[index]
    end

    def self.days_per_month
      DAYS_PER_MONTH
    end

    def to_formatted_string
      calendar_data = to_equinox_calendar

      case calendar_data[:type]
      when :year_day
        "Year Day, #{calendar_data[:cycle_year]}"
      when :leap_day
        "Leap Day, #{calendar_data[:cycle_year]}"
      when :regular
        day_of_week_index = (calendar_data[:day] - 1) % 7
        day_name = DAY_NAMES[day_of_week_index]
        "#{day_name}, #{calendar_data[:month_name]} #{calendar_data[:day]}, #{calendar_data[:cycle_year]}"
      end
    end
  end
end
