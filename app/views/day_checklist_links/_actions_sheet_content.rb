# frozen_string_literal: true

module Views
  module DayChecklistLinks
    class ActionsSheetContent < ::Views::Base
      def initialize(checklist:, day:, item_index: nil, total_items: nil)
        @checklist = checklist
        @day = day
        @item_index = item_index
        @total_items = total_items
      end

      def view_template
        div(id: "sheet_content_area") do
          SheetHeader do
            SheetTitle { @checklist.name }
            SheetDescription do
              div { "Checklist • #{@checklist.flow.titleize}" }
              completed_count = @checklist.items.count { |item| item["completed_at"].present? }
              total_count = @checklist.items.length
              div { "#{completed_count}/#{total_count} complete" }
            end
          end

          SheetMiddle(class: "py-4 space-y-4") do
            render ActionButtons.new(
              checklist: @checklist,
              day: @day,
              item_index: @item_index,
              total_items: @total_items
            )
          end
        end
      end
    end
  end
end
