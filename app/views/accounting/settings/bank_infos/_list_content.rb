module Views
  module Accounting
    module Settings
      module BankInfos
        class ListContent < Views::Base
          def initialize(user:, **attrs)
            @user = user
            @bank_infos = @user.bank_infos.where(kind: :user)
            super(**attrs)
          end

          def view_template
            if @bank_infos.empty?
              div(class: "flex h-full flex-col items-center justify-center") do
                p(class: "text-sm text-gray-500") { "No bank infos found" }
              end
            else
              @bank_infos.each do |bank_info|
                div(id: "bank_info_#{bank_info.id}_div", class: "mt-2") do
                  render Views::Accounting::Settings::BankInfos::BankInfoRow.new(bank_info: bank_info)
                end
              end
            end
          end
        end
      end
    end
  end
end
