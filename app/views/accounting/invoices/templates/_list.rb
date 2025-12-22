module Views
  module Accounting
    module Invoices
      module Templates
        class List < Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            # Container for Turbo Stream updates
            div(id: "invoice_templates_list") do
              render Views::Accounting::Invoices::Templates::ListContent.new(user: @user)
            end 
          end
        end
      end
    end
  end
end