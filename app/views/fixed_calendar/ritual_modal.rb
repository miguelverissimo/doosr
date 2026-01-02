# frozen_string_literal: true

module Views
  module FixedCalendar
    class RitualModal < ::Views::Base
      def initialize(ritual:)
        @ritual = ritual
      end

      def view_template
        # Wrapper for backdrop and dialog
        div do
          # Backdrop
          div(
            class: "fixed inset-0 z-50 bg-black/80 backdrop-blur-sm",
            data: { controller: "dialog-closer", action: "click->dialog-closer#close" }
          )

          # Modal dialog
          div(
            role: "dialog",
            class: "fixed left-[50%] top-[50%] z-50 w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4 border bg-background p-6 shadow-lg duration-200 sm:rounded-lg",
            data: { controller: "dialog-closer" }
          ) do
            # Header
            div(class: "flex flex-col space-y-2 text-center sm:text-left mb-4") do
              h2(class: "text-lg font-semibold") { @ritual[:name] }
              p(class: "text-sm text-muted-foreground") do
                plain "Gregorian: #{@ritual[:gregorian]}"
              end
            end

            # Content
            div(class: "space-y-4") do
              # Purpose
              div do
                h3(class: "text-sm font-semibold mb-2") { "Purpose" }
                p(class: "text-sm text-muted-foreground") { @ritual[:purpose] }
              end

              # Action
              div do
                h3(class: "text-sm font-semibold mb-2") { "Action" }
                p(class: "text-sm text-muted-foreground") { @ritual[:action] }
              end

              # Symbolism
              div do
                h3(class: "text-sm font-semibold mb-2") { "Symbolism" }
                p(class: "text-sm text-muted-foreground") { @ritual[:symbolism] }
              end
            end

            # Footer
            div(class: "flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2 mt-6") do
              button(
                type: "button",
                class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2",
                data: { action: "click->dialog-closer#close" }
              ) { "Close" }
            end
          end
        end
      end
    end
  end
end
