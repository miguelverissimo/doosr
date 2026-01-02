# frozen_string_literal: true

module Views
  module FixedCalendar
    class Index < ::Views::Base
      def initialize(target_date:, calendar_data:)
        @target_date = target_date
        @calendar_data = calendar_data
      end

      def view_template
        div(class: "max-w-7xl mx-auto") do
          # Year display at top
          if @calendar_data[:cycle_year]
            div(class: "mb-6 text-center") do
              h2(class: "text-4xl font-bold") { @calendar_data[:cycle_year].to_s }
              div(class: "text-sm text-muted-foreground mt-1") do
                plain "Fixed Calendar Year (started #{@calendar_data[:year_cycle_start].strftime('%B %d, %Y')} gregorian)"
              end
            end
          end

          # Current date info
          div(class: "mb-4 flex items-center gap-4 text-sm text-muted-foreground") do
            div do
              span(class: "font-medium") { "Today: " }
              plain @target_date.strftime("%B %d, %Y")
            end
            div do
              span(class: "font-medium") { "Fixed: " }
              plain @calendar_data[:display]
            end
          end

          # Calendar grid with leap day after Junius and year day at end
          render_calendar_grid
        end
      end

      private

      def render_calendar_grid
        year = @target_date.year
        start_date = Date.new(year, 3, 20)
        start_date = Date.new(year - 1, 3, 20) if @target_date < start_date
        is_leap = Date.leap?(start_date.year)

        div(class: "grid grid-cols-3 gap-4 mb-6") do
          # First 6 months (Ianuarius through Junius)
          (0..5).each do |month_idx|
            current_day = (@calendar_data[:type] == :regular && @calendar_data[:month_index] == month_idx) ? @calendar_data[:day] : nil
            render Components::Calendar::MonthView.new(
              month_name: ::FixedCalendar::Converter::MONTHS[month_idx],
              current_day: current_day
            )
          end

          # Leap Day (after Junius, only in leap years)
          if is_leap
            render_leap_day_box
          end

          # Next 7 months (Sol through December)
          (6..12).each do |month_idx|
            current_day = (@calendar_data[:type] == :regular && @calendar_data[:month_index] == month_idx) ? @calendar_data[:day] : nil
            render Components::Calendar::MonthView.new(
              month_name: ::FixedCalendar::Converter::MONTHS[month_idx],
              current_day: current_day
            )
          end

          # Year Day (last day of the year)
          render_year_day_box
        end
      end

      def render_leap_day_box
        is_leap_day = @calendar_data[:type] == :leap_day

        div(class: "w-full") do
          # Header
          div(class: "text-center font-semibold text-sm mb-2") do
            plain "Leap Day"
          end

          # Box
          div(class: "border border-border rounded-md overflow-hidden") do
            div(class: "grid grid-cols-1") do
              div(class: special_day_classes(is_leap_day)) do
                plain "Leap Day"
              end
            end
          end
        end
      end

      def render_year_day_box
        is_year_day = @calendar_data[:type] == :year_day

        div(class: "w-full") do
          # Header
          div(class: "text-center font-semibold text-sm mb-2") do
            plain "Year Day"
          end

          # Box
          div(class: "border border-border rounded-md overflow-hidden") do
            div(class: "grid grid-cols-1") do
              div(class: special_day_classes(is_year_day)) do
                plain "Year Day"
              end
            end
          end
        end
      end

      def special_day_classes(is_current)
        base = "text-center py-8 text-sm border-border"

        if is_current
          "#{base} bg-primary text-primary-foreground font-semibold"
        else
          "#{base} hover:bg-accent hover:text-accent-foreground transition-colors"
        end
      end
    end
  end
end
