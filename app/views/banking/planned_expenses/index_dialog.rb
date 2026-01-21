# frozen_string_literal: true

module Views
  module Banking
    module PlannedExpenses
      class IndexDialog < ::Views::Base
        def initialize(planned_expenses:, categories:)
          @planned_expenses = planned_expenses
          @categories = categories
        end

        def view_template
          div(id: "planned_expenses_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :xl) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Planned Expenses" }
                  render RubyUI::DialogDescription.new { "Manage your upcoming one-time and recurring expenses" }
                end

                render RubyUI::DialogMiddle.new do
                  render ::Views::Banking::PlannedExpenses::TabsContent.new(planned_expenses: @planned_expenses)
                end
              end
            end
          end
        end
      end
    end
  end
end
