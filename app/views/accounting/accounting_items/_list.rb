module Views
  module Accounting
    module AccountingItems
      class List < Views::Base
        def initialize(user:)
          @user = user
        end

        def view_template
          # Container for Turbo Stream updates
          div(id: "accounting_items_list") do
            render Views::Accounting::AccountingItems::ListContent.new(user: @user)
          end
        end
      end
    end
  end
end