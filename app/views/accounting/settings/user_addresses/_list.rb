module Views
  module Accounting
    module Settings
      module UserAddresses
        class List < Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            # Container for Turbo Stream updates
            div(id: "addresses_list") do
              render Views::Accounting::Settings::UserAddresses::ListContent.new(user: @user)
            end
          end
        end
      end
    end
  end
end