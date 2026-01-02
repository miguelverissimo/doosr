# frozen_string_literal: true

module Views
  module FixedCalendar
    class Header < ::Views::Base
      def view_template
        div(class: "flex items-center gap-3 flex-1") do
          # Title display
          div do
            h1(class: "font-semibold text-base") { "Fixed Calendar" }
          end

          # Spacer
          div(class: "flex-1")
        end
      end
    end
  end
end
