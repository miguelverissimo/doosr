module Views
  module Accounting
    module Receipts
      class ListContent < Views::Base
        def initialize(user:, **attrs)
          @user = user
          @receipts = \
            user.receipts
            .includes(:invoice)
            .includes(:items)
            .includes(:receipt_items)
            .order(issue_date: :desc)
          super(**attrs)
        end

        def view_template
          if @receipts.empty?
            div(class: "flex h-full flex-col items-center justify-center") do
              p(class: "text-sm text-gray-500") { "No receipts found" }
            end
          else
            @receipts.each do |receipt|
              div(id: "receipt_#{receipt.id}_div", class: "mt-2") do
                render Views::Accounting::Receipts::ReceiptRow.new(receipt: receipt)
              end
            end
          end
        end
      end
    end
  end
end