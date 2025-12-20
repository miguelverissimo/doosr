module Views
  module Accounting
    module Customers
      class List < Views::Base
        def initialize(user:)
          @user = user
        end

        def view_template
          # Container for Turbo Stream updates
          div(id: "customers_list") do
            render Views::Accounting::Customers::ListContent.new(user: @user)
          end
        end
      end
    end
  end
end