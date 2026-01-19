# frozen_string_literal: true

module Views
  module Banking
    module RecurringGroups
      class IndexDialog < ::Views::Base
        def initialize(recurring_groups:, total_monthly:)
          @recurring_groups = recurring_groups
          @total_monthly = total_monthly
        end

        def view_template
          div(id: "recurring_groups_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Recurring Transactions" }
                  render RubyUI::DialogDescription.new do
                    plain "View detected recurring expenses and income patterns"
                  end
                end

                render RubyUI::DialogMiddle.new do
                  div(id: "recurring_groups_content") do
                    render List.new(
                      recurring_groups: @recurring_groups,
                      total_monthly: @total_monthly
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
end
