module Views
  module Accounting
    module Customers
      class Index < ::Views::Base
        def initialize
        end

        def view_template
          div(class: "flex h-full flex-col") do
            render RubyUI::Dialog.new do
              div(class: "flex items-center justify-between mb-2") do
                render RubyUI::DialogTitle.new { "Customers" }
                render RubyUI::DialogTrigger.new do
                  Button(variant: :primary, size: :sm) { "Add Customer" }
                end
              end

              render ::Views::Accounting::Customers::List.new(user: view_context.current_user)
              render_customer_form_dialog
            end
          end
        end

        def render_customer_form_dialog(customer: nil)
          render RubyUI::DialogContent.new(size: :lg) do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogDescription.new { "Manage customer" }
            end

            render RubyUI::DialogMiddle.new do
              render ::Components::Accounting::Customers::Form.new(customer: customer)
            end
          end
        end
      end
    end
  end
end