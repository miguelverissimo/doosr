module Views
  module Accounting
    module AccountingItems
      class Index < ::Views::Base
        def initialize
        end

        def view_template
          div(class: "flex h-full flex-col") do
            render RubyUI::Dialog.new do
              div(class: "flex items-center justify-between mb-2") do
                render RubyUI::DialogTitle.new { "Accounting Items" }
                render RubyUI::DialogTrigger.new do
                  Button(variant: :primary, size: :sm) { "Add Accounting Item" }
                end
              end

              render ::Views::Accounting::AccountingItems::List.new(user: view_context.current_user)
              render_accounting_item_form_dialog
            end
          end
        end

        def render_accounting_item_form_dialog(accounting_item: nil)
          render RubyUI::DialogContent.new(size: :lg) do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogDescription.new { "Manage accounting item" }
            end

            render RubyUI::DialogMiddle.new do
              render ::Components::Accounting::AccountingItems::Form.new(accounting_item: accounting_item)
            end
          end
        end
      end
    end
  end
end
