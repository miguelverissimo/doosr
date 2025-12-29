module Views
  module Accounting
    module Receipts
      module ReceiptItems
        class ListContent < ::Views::Base
          def initialize(user:, **attrs)
            @user = user
            @receipt_items = user.receipt_items.order(created_at: :desc)
            super(**attrs)
          end

          def view_template
            turbo_frame_tag "receipt_items_content" do
              if @receipt_items.empty?
                div(class: "flex h-full flex-col items-center justify-center") do
                  p(class: "text-sm text-gray-500") { "No receipt items found" }
                end
              else
                @receipt_items.each do |receipt_item|
                  render ::Views::Accounting::Receipts::ReceiptItems::ReceiptItemRow.new(receipt_item: receipt_item)
                end
              end
            end
          end
        end
      end
    end
  end
end
