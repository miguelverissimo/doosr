module Views
  module Accounting
    module Invoices
        class List < Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            # Container for Turbo Stream updates
            div(id: "invoices_list") do
              render Views::Accounting::Invoices::ListContent.new(user: @user)
            end 
          end
        end
    end
  end
end