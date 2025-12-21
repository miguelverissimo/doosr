module Views
  module Accounting
    module Settings
      module Logos
        class List < Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            # Container for Turbo Stream updates
            div(id: "accounting_logos_list") do
              render Views::Accounting::Settings::Logos::ListContents.new(user: @user)
            end
          end
        end
      end
    end
  end
end