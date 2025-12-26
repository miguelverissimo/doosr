module Views
  module Accounting
    module Receipts
      module ReceiptItems
        class ListContent < Views::Base
          def initialize(user:, **attrs)
            @user = user
            @receipt_items = user.receipt_items.order(created_at: :desc)
            super(**attrs)
          end

          def view_template
            if @receipt_items.empty?
              div(class: "flex h-full flex-col items-center justify-center") do
                p(class: "text-sm text-gray-500") { "No receipt items found" }
              end
            else
              @receipt_items.each do |receipt_item|
                div(id: "receipt_item_#{receipt_item.id}_div", class: "mt-2") do
                  render Views::Accounting::Receipts::ReceiptItems::ReceiptItemRow.new(receipt_item: receipt_item)
                end
              end
            end
          end
        end
      end
    end
  end
end