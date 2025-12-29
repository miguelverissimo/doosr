# frozen_string_literal: true

module Views
  module Ephemeries
    class Card < ::Views::Base
      def initialize(ephemery:, selected_date:)
        @ephemery = ephemery
        @selected_date = selected_date
      end

      def view_template
        div(class: "border rounded-lg p-4 space-y-2 bg-card") do
          # Header row: "Dec 7 – Dec 10 • Strongest: Today"
          div(class: "text-sm text-muted-foreground mb-2") do
            plain "#{format_date_range} • Strongest: #{format_strongest_label}"
          end

          # Body
          div(class: "space-y-1") do
            # Aspect heading
            p(class: "font-semibold text-sm") { @ephemery.aspect }

            # Description
            p(class: "text-sm text-muted-foreground leading-relaxed") { @ephemery.description }
          end
        end
      end

      private

      def format_date_range
        start_str = @ephemery.start.strftime("%b %-d")
        end_str = @ephemery.end.strftime("%b %-d")
        "#{start_str} – #{end_str}"
      end

      def format_strongest_label
        return "N/A" if @ephemery.strongest.nil?

        # Normalize dates to compare (UTC midnight)
        strongest_date = @ephemery.strongest.to_date
        selected_date = @selected_date.to_date

        case strongest_date
        when selected_date
          "Today"
        when selected_date + 1
          "Tomorrow"
        when selected_date - 1
          "Yesterday"
        else
          @ephemery.strongest.strftime("%b %-d")
        end
      end
    end
  end
end
