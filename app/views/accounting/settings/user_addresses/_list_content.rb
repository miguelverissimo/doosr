module Views
  module Accounting
    module Settings
      module UserAddresses
        class ListContent < Views::Base
          def initialize(user:, **attrs)
            @user = user
            @addresses = ::Address.where(user: @user, address_type: :user)
            super(**attrs)
          end

          def view_template
            if @addresses.empty?
              div(class: "flex h-full flex-col items-center justify-center") do
                p(class: "text-sm text-gray-500") { "No addresses found" }
              end
            else
              @addresses.each do |address|
                div(id: "address_#{address.id}_div", class: "mt-2") do
                  render Views::Accounting::Settings::UserAddresses::AddressRow.new(address: address)
                end
              end
            end
          end
        end
      end
    end
  end
end