module Views
  module Accounting
    module Receipts
      class List < Views::Base
        def initialize(user:)
          @user = user
        end

        def view_template
          # Container for Turbo Stream updates
          div(id: "receipts_list") do
            render Views::Accounting::Receipts::ListContent.new(user: @user)
          end
        end
      end
    end
  end
end