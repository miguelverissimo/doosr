module Views
  module Accounting
    module Receipts
      module ReceiptItems
        class List < Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            # Container for Turbo Stream updates
            div(id: "receipt_items_list") do
              render Views::Accounting::Receipts::ReceiptItems::ListContent.new(user: @user)
            end
          end
        end
      end
    end
  end
end