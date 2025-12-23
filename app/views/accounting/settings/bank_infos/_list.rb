module Views
  module Accounting
    module Settings
      module BankInfos
        class List < Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            div(id: "bank_infos_list") do
              render Views::Accounting::Settings::BankInfos::ListContent.new(user: @user)
            end
          end
        end
      end
    end
  end
end
