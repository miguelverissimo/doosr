module Components
  module Shared
    class LoadingSpinner < ::Components::Base
      def initialize(message: "Loading...", **attrs)
        @message = message
        super(**attrs)
      end

      def view_template
        div(class: "flex h-full flex-col items-center justify-center py-12") do
          # Spinner SVG
          svg(
            class: "animate-spin h-8 w-8 text-gray-400 mb-4",
            xmlns: "http://www.w3.org/2000/svg",
            fill: "none",
            viewBox: "0 0 24 24"
          ) do |s|
            s.circle(
              class: "opacity-25",
              cx: "12",
              cy: "12",
              r: "10",
              stroke: "currentColor",
              stroke_width: "4"
            )
            s.path(
              class: "opacity-75",
              fill: "currentColor",
              d: "M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            )
          end

          p(class: "text-sm text-gray-500") { @message }
        end
      end
    end
  end
end
