# frozen_string_literal: true

module Views
  module Banking
    module Forecasts
      class CalendarDialog < ::Views::Base
        def initialize(planned_expenses:)
          @planned_expenses = planned_expenses
        end

        def view_template
          div(id: "forecast_calendar_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :xl) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Expense Calendar" }
                  render RubyUI::DialogDescription.new { "View your planned expenses over the next 12 weeks" }
                end

                render RubyUI::DialogMiddle.new do
                  render ::Views::Banking::PlannedExpenses::Calendar.new(
                    planned_expenses: @planned_expenses
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
