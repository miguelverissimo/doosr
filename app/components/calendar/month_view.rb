# frozen_string_literal: true

module Components
  module Calendar
    class MonthView < ::Components::Base
      def initialize(month_name:, month_index:, current_day: nil, **attrs)
        @month_name = month_name
        @month_index = month_index
        @current_day = current_day
        super(**attrs)
      end

      def view_template
        div(class: "w-full") do
          # Month header
          div(class: "text-center font-semibold text-sm mb-2") do
            plain @month_name
          end

          # Calendar grid
          div(class: "border border-border rounded-md overflow-hidden") do
            # Days of week header
            div(class: "grid grid-cols-7 bg-muted") do
              %w[S M T W T F S].each do |day|
                div(class: "text-center text-xs font-medium py-1 text-muted-foreground") do
                  plain day
                end
              end
            end

            # Days grid (always 4 weeks, 28 days)
            div(class: "grid grid-cols-7") do
              (1..28).each do |day|
                is_current = day == @current_day
                ritual = FixedCalendar::Converter.ritual_for_day(@month_index, day)

                cell_attrs = {
                  class: day_cell_classes(is_current, ritual)
                }

                if ritual
                  cell_attrs.merge!(
                    data: {
                      controller: "fixed-calendar-ritual",
                      action: "click->fixed-calendar-ritual#showRitual",
                      fixed_calendar_ritual_month_value: @month_index,
                      fixed_calendar_ritual_day_value: day
                    },
                    title: "#{ritual[:name]} - Click to view details"
                  )
                end

                div(**cell_attrs) do
                  plain day.to_s
                end
              end
            end
          end
        end
      end

      private

      def day_cell_classes(is_current, ritual)
        base = "text-center py-1 text-xs border-t border-border"

        if is_current
          "#{base} bg-primary text-primary-foreground font-semibold"
        elsif ritual
          "#{base} bg-rose-500/10 text-rose-500 cursor-pointer hover:bg-rose-500/20 transition-colors"
        else
          "#{base} hover:bg-accent hover:text-accent-foreground transition-colors"
        end
      end
    end
  end
end
