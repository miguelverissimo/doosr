module Views
  module Accounting
    module Receipts
      class Index < ::Views::Base
        def initialize(user:, page: 1, search_query: nil, invoice_number: nil, date_from: nil, date_to: nil)
          @user = user
          @page = page
          @search_query = search_query
          @invoice_number = invoice_number
          @date_from = date_from
          @date_to = date_to
        end

        def view_template
          div(class: "flex h-full flex-col") do
            tabs_data = [
              { value: "receipts", label: "Receipts" },
              { value: "receipt_items", label: "Receipt Items" }
            ]
            Tabs(default_value: "receipts") do
              render RubyUI::ResponsiveTabsList.new(
                tabs: tabs_data,
                current_value: "receipts"
              )
              TabsContent(value: "receipts") do
                div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground", data: { controller: "receipts-pagination" }) do
                  div(class: "flex items-center justify-between mb-4") do
                    h3(class: "text-lg font-semibold") { "Receipts" }
                    div(class: "flex gap-2") do
                      render_receipt_form_with_calculator_dialog
                      render_receipt_form_dialog
                    end
                  end

                  # Search form
                  render_search_form

                  # Loading spinner (hidden by default)
                  div(
                    id: "receipts_loading_spinner",
                    class: "hidden",
                    data: { receipts_pagination_target: "spinner" }
                  ) do
                    render ::Components::Shared::LoadingSpinner.new(message: "Loading receipts...")
                  end

                  # Receipts content (ListContent provides the wrapper with ID and data attribute)
                  render ::Views::Accounting::Receipts::ListContent.new(
                    user: @user,
                    page: @page,
                    search_query: @search_query,
                    invoice_number: @invoice_number,
                    date_from: @date_from,
                    date_to: @date_to
                  )
                end
              end

              TabsContent(value: "receipt_items") do
                div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                  div(class: "flex items-center justify-between mb-4") do
                    h3(class: "text-lg font-semibold") { "Receipt Items" }
                    render_receipt_item_form_dialog
                  end
                  div(id: "receipt_items_list") do
                    render ::Views::Accounting::Receipts::ReceiptItems::ListContent.new(user: @user)
                  end
                end
              end
            end
          end
        end

        private

        def render_search_form
          form(
            action: view_context.receipts_path,
            method: "get",
            data: {
              turbo_stream: true,
              action: "submit->receipts-pagination#showSpinner"
            },
            class: "space-y-3 mb-4"
          ) do
            div(class: "flex flex-row items-end gap-4") do
              div(class: "flex-1") do
                label(class: "text-sm font-medium mb-1 block") { "Search by Reference" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "search_query",
                  placeholder: "Receipt reference",
                  value: @search_query
                )
              end

              div(class: "flex-1") do
                label(class: "text-sm font-medium mb-1 block") { "Invoice Number" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "invoice_number",
                  placeholder: "e.g., 9/2025",
                  value: @invoice_number
                )
              end

              div(class: "flex-1") do
                label(class: "text-sm font-medium mb-1 block") { "From Date" }
                render RubyUI::Input.new(
                  type: :date,
                  name: "date_from",
                  class: "date-input-icon-light text-primary-foreground",
                  value: @date_from
                )
              end

              div(class: "flex-1") do
                label(class: "text-sm font-medium mb-1 block") { "To Date" }
                render RubyUI::Input.new(
                  type: :date,
                  name: "date_to",
                  class: "date-input-icon-light text-primary-foreground",
                  value: @date_to
                )
              end

              div(class: "flex gap-2") do
                Button(variant: :primary, type: :submit) { "Search" }
                if @search_query.present? || @invoice_number.present? || @date_from.present? || @date_to.present?
                  a(
                    href: view_context.receipts_path,
                    data: {
                      turbo_stream: true,
                      action: "click->receipts-pagination#showSpinner"
                    },
                    class: "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors h-9 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground"
                  ) { "Clear" }
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
                render ::Components::Accounting::Receipts::FormWithCalculator.new(receipt: receipt)
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
                render ::Components::Accounting::Receipts::Form.new(receipt: receipt)
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
                render ::Components::Accounting::Receipts::ReceiptItemForm.new(receipt_item: receipt_item)
              end
            end
          end
        end
      end
    end
  end
end
