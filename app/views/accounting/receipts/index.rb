module Views
  module Accounting
    module Receipts
      class Index < Views::Base
        def initialize
        end

        def view_template
          div(class: "flex h-full flex-col") do
            tabs_data = [
              {value: "receipts", label: "Receipts"},
              {value: "receipt_items", label: "Receipt Items"},
            ]
            Tabs(default_value: "receipts") do
              render RubyUI::ResponsiveTabsList.new(
                tabs: tabs_data,
                current_value: "receipts"
              )
              TabsContent(value: "receipts") do
                div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                  div(class: "flex items-center justify-between mb-4") do
                    h3(class: "text-lg font-semibold") { "Receipts" }
                    div(class: "flex gap-2") do
                      render_receipt_form_with_calculator_dialog
                      render_receipt_form_dialog
                    end
                  end
                  # render Views::Accounting::Receipts::List.new(user: view_context.current_user)
                end
              end

              TabsContent(value: "receipt_items") do
                div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                  div(class: "flex items-center justify-between mb-4") do
                    h3(class: "text-lg font-semibold") { "Receipt Items" }
                    render_receipt_item_form_dialog
                  end
                  render Views::Accounting::Receipts::ReceiptItems::List.new(user: view_context.current_user)
                end
              end
            end
          end
        end

        def render_receipt_form_with_calculator_dialog(receipt: nil)
          render RubyUI::Dialog.new do
            render RubyUI::DialogTrigger.new do
              Button(variant: :primary, size: :sm) { "Add with Calculator" }
            end

            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Add Receipt with Calculator" }
                render RubyUI::DialogDescription.new { "Create a new receipt using the calculator" }
              end

              render RubyUI::DialogMiddle.new do
                render Components::Accounting::Receipts::FormWithCalculator.new(receipt: receipt)
              end
            end
          end
        end

        def render_receipt_form_dialog(receipt: nil)
          render RubyUI::Dialog.new do
            render RubyUI::DialogTrigger.new do
              Button(variant: :secondary, size: :sm) { "Add Receipt" }
            end

            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Add Receipt" }
                render RubyUI::DialogDescription.new { "Create a new receipt" }
              end

              render RubyUI::DialogMiddle.new do
                render Components::Accounting::Receipts::Form.new(receipt: receipt)
              end
            end
          end
        end

        def render_receipt_item_form_dialog(receipt_item: nil)
          render RubyUI::Dialog.new do
            render RubyUI::DialogTrigger.new do
              Button(variant: :primary, size: :sm) { "Add Item" }
            end

            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Add Item" }
                render RubyUI::DialogDescription.new { "Create a new item" }
              end

              render RubyUI::DialogMiddle.new do
                render Components::Accounting::Receipts::ReceiptItemForm.new(receipt_item: receipt_item)
              end
            end
          end
        end
      end
    end
  end
end