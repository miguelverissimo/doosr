module Views
  module Accounting
    module Customers
      class ListContent < ::Views::Base
        def initialize(user:, **attrs)
          @user = user
          @customers = ::Accounting::Customer.where(user: @user).includes(:address)
          super(**attrs)
        end

        def view_template
          turbo_frame_tag "customers_content" do
            if @customers.empty?
              div(class: "flex h-full flex-col items-center justify-center") do
                p(class: "text-sm text-gray-500") { "No customers found" }
              end
            else
              @customers.each do |customer|
                div(id: "customer_#{customer.id}_div", class: "mt-2") do
                  render ::Views::Accounting::Customers::CustomerRow.new(customer: customer)
                end
              end
            end
          end
        end
      end
    end
  end
end
