module Components
  module Accounting
    module Receipts
      class Form < ::Components::Base
        def initialize(receipt: nil, invoice: nil, receipt_items: nil, available_invoices: nil)
          @receipt = receipt || ::Accounting::Receipt.new
          @invoice = invoice
          @is_new_record = @receipt.new_record?
          @action = @is_new_record ? "Create" : "Update"
          @receipt_items_passed = receipt_items
          @available_invoices_passed = available_invoices
          super(**attrs)
        end

        def view_template
          form_url = if @is_new_record
            view_context.receipts_path
          else
            view_context.receipt_path(@receipt)
          end

          # Query or use passed receipt items
          user = view_context.current_user
          if @receipt_items_passed.present?
            manev_h_item = @receipt_items_passed[:manev_h]
            manev_on_call_item = @receipt_items_passed[:manev_on_call]
            token_item = @receipt_items_passed[:token]
          else
            manev_h_item = user&.receipt_items&.find_by(reference: "OUT - MANEV-H")
            manev_on_call_item = user&.receipt_items&.find_by(reference: "OUT - MANEV-ON-CALL")
            token_item = user&.receipt_items&.find_by(reference: "OUT - TOKEN")
          end

          # Query or use passed available invoices
          available_invoices = if @available_invoices_passed.present?
            if @invoice.present?
              (@available_invoices_passed + [ @invoice ]).uniq
            else
              @available_invoices_passed
            end
          elsif user
            # Show only invoices with state "sent" or "partial" (exclude "paid" and "draft")
            invoices_query = user.invoices.where(state: [ :sent, :partial ])

            if @invoice.present?
              invoices_query = invoices_query.where(
                "id = ? OR (id NOT IN (?))",
                @invoice.id,
                ::Accounting::Receipt.where.not(invoice_id: nil).select(:invoice_id)
              )
            elsif @receipt&.invoice_id.present?
              invoices_query = invoices_query.where(
                "id NOT IN (?) OR id = ?",
                ::Accounting::Receipt.where.not(invoice_id: nil).where.not(id: @receipt.id).select(:invoice_id),
                @receipt.invoice_id
              )
            else
              invoices_query = invoices_query.where.not(
                id: ::Accounting::Receipt.where.not(invoice_id: nil).select(:invoice_id)
              )
            end

            invoices_query.order(year: :desc, number: :desc)
          else
            []
          end

          # Get existing quantities from receipt items if editing
          existing_manev_h_quantity = @receipt.items.find { |item| item.receipt_item&.reference == "OUT - MANEV-H" }&.quantity&.to_i || 0
          existing_manev_on_call_quantity = @receipt.items.find { |item| item.receipt_item&.reference == "OUT - MANEV-ON-CALL" }&.quantity&.to_i || 0
          existing_token_quantity = @receipt.items.find { |item| item.receipt_item&.reference == "OUT - TOKEN" }&.quantity&.to_i || 0

          render RubyUI::Form.new(
            action: form_url,
            method: "post",
            class: "space-y-6",
            data: {
              turbo: true,
              action: "turbo:submit-end@document->ruby-ui--dialog#dismiss",
              controller: "receipt-form form-loading payment-type-toggle",
              receipt_form_manev_h_unit_price_value: manev_h_item&.unit_price_with_tax || 0,
              receipt_form_manev_on_call_unit_price_value: manev_on_call_item&.unit_price_with_tax || 0,
              receipt_form_token_unit_price_value: token_item&.unit_price_with_tax || 0,
              form_loading_message_value: "Creating receipt..."
            }
          ) do
            # Hidden fields for Rails
            input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            input(type: :hidden, name: "_method", value: "patch") unless @is_new_record
            input(
              type: :hidden,
              name: "receipt[value]",
              value: @receipt&.value_in_units&.to_s || "0",
              data: { receipt_form_target: "receiptValue" }
            )

            # Receipt items section
            div(class: "space-y-6") do
              h3(class: "text-lg font-semibold mb-4") { "Receipt Items" }

              # Show message if ReceiptItems are missing
              unless manev_h_item && manev_on_call_item && token_item
                div(class: "p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-md") do
                  p(class: "text-sm text-yellow-800 dark:text-yellow-200") do
                    "Please create the required ReceiptItems first: OUT - MANEV-H, OUT - MANEV-ON-CALL, and OUT - TOKEN"
                  end
                end
              end

              # OUT - MANEV-H quantity input
              if manev_h_item
                render_quantity_field(
                  label: manev_h_item.description,
                  reference: "OUT - MANEV-H",
                  name: "manevH",
                  receipt_item_id: manev_h_item.id,
                  initial_quantity: existing_manev_h_quantity,
                  min: 0
                )
              end

              # OUT - MANEV-ON-CALL quantity input
              if manev_on_call_item
                render_quantity_field(
                  label: manev_on_call_item.description,
                  reference: "OUT - MANEV-ON-CALL",
                  name: "manevOnCall",
                  receipt_item_id: manev_on_call_item.id,
                  initial_quantity: existing_manev_on_call_quantity,
                  min: 0
                )
              end

              # OUT - TOKEN quantity input
              if token_item
                render_quantity_field(
                  label: token_item.description,
                  reference: "OUT - TOKEN",
                  name: "token",
                  receipt_item_id: token_item.id,
                  initial_quantity: existing_token_quantity,
                  min: 0
                )
              end

              # Total display
              div(class: "pt-4 border-t") do
                div(class: "flex items-center justify-between") do
                  span(class: "text-sm font-medium") { "Total" }
                  span(
                    class: "text-lg font-semibold",
                    data: {
                      receipt_form_target: "totalDisplay"
                    }
                  ) { "EUR 0.00" }
                end
              end
            end

            # Receipt fields section
            div(class: "space-y-6 pt-6 border-t") do
              h3(class: "text-lg font-semibold mb-4") { "Receipt Details" }

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Reference" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "receipt[reference]",
                  placeholder: "Enter reference",
                  value: @receipt&.reference.to_s,
                  required: true
                )
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Kind" }
                select(
                  name: "receipt[kind]",
                  class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                  required: true
                ) do
                  ::Accounting::Receipt.kinds.each_key do |kind|
                    option(
                      value: kind,
                      selected: @receipt&.kind == kind.to_s || "invoice_receipt"
                    ) { kind.to_s.humanize }
                  end
                end
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Invoice" }
                select(
                  name: "receipt[invoice_id]",
                  class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                  disabled: @invoice.present? || available_invoices.empty?
                ) do
                  option(value: "", selected: @receipt&.invoice_id.nil? && @invoice.nil?) { "None" }
                  available_invoices.each do |invoice|
                    option(
                      value: invoice.id,
                      selected: (@receipt&.invoice_id == invoice.id) || (@invoice&.id == invoice.id)
                    ) { invoice.display_number }
                  end
                end
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Issue Date" }
                render RubyUI::Input.new(
                  type: :date,
                  name: "receipt[issue_date]",
                  class: "date-input-icon-light text-primary-foreground",
                  value: (@receipt&.issue_date || Date.today).strftime("%Y-%m-%d"),
                  required: true
                )
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Payment Date" }
                render RubyUI::Input.new(
                  type: :date,
                  name: "receipt[payment_date]",
                  class: "date-input-icon-light text-primary-foreground",
                  value: (@receipt&.payment_date || Date.today).strftime("%Y-%m-%d"),
                  required: true
                )
                render RubyUI::FormFieldError.new
              end

              # Payment type selection (only show if invoice is selected)
              if @invoice.present? || available_invoices.any?
                current_payment_type = @receipt&.payment_type || "total"
                render RubyUI::FormField.new do
                  render RubyUI::FormFieldLabel.new { "Payment Type" }
                  div(class: "space-y-3") do
                    div(class: "flex items-center space-x-2") do
                      render RubyUI::RadioButton.new(
                        name: "receipt[payment_type]",
                        id: "payment_type_total",
                        value: "total",
                        checked: current_payment_type == "total"
                      )
                      render RubyUI::FormFieldLabel.new(for: "payment_type_total") { "Total Payment" }
                    end
                    div(class: "flex items-center space-x-2") do
                      render RubyUI::RadioButton.new(
                        name: "receipt[payment_type]",
                        id: "payment_type_partial",
                        value: "partial",
                        checked: current_payment_type == "partial"
                      )
                      render RubyUI::FormFieldLabel.new(for: "payment_type_partial") { "Partial Payment" }
                    end
                  end
                end

                # Switch to mark invoice as fully paid (checked and disabled when total is selected)
                div(
                  id: "mark_fully_paid_container",
                  data: { payment_type_toggle_target: "container" }
                ) do
                  render RubyUI::FormField.new do
                    div(class: "flex items-center gap-2") do
                      render RubyUI::Switch.new(
                        name: "mark_fully_paid",
                        id: "mark_fully_paid",
                        checked: @receipt&.completes_payment || current_payment_type == "total",
                        disabled: current_payment_type == "total",
                        data: { payment_type_toggle_target: "switch" }
                      )
                      label(for: "mark_fully_paid", class: "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70") do
                        "Completes payment"
                      end
                    end
                  end
                end
              end
            end

            # Hidden fields for items (populated by Stimulus)
            if manev_h_item
              input(
                type: :hidden,
                name: "receipt[items_attributes][0][receipt_item_id]",
                value: manev_h_item.id,
                data: { receipt_form_target: "manevHReceiptItemId" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][0][quantity]",
                value: existing_manev_h_quantity.to_s,
                data: { receipt_form_target: "manevHQuantity" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][0][value_with_tax]",
                value: "0",
                data: { receipt_form_target: "manevHValueWithTax" }
              )
            end

            if manev_on_call_item
              input(
                type: :hidden,
                name: "receipt[items_attributes][1][receipt_item_id]",
                value: manev_on_call_item.id,
                data: { receipt_form_target: "manevOnCallReceiptItemId" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][1][quantity]",
                value: existing_manev_on_call_quantity.to_s,
                data: { receipt_form_target: "manevOnCallQuantity" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][1][value_with_tax]",
                value: "0",
                data: { receipt_form_target: "manevOnCallValueWithTax" }
              )
            end

            if token_item
              input(
                type: :hidden,
                name: "receipt[items_attributes][2][receipt_item_id]",
                value: token_item.id,
                data: { receipt_form_target: "tokenReceiptItemId" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][2][quantity]",
                value: existing_token_quantity.to_s,
                data: { receipt_form_target: "tokenQuantity" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][2][value_with_tax]",
                value: "0",
                data: { receipt_form_target: "tokenValueWithTax" }
              )
            end

            div(class: "flex gap-2 justify-end mt-6") do
              Button(variant: :outline, type: "button", data: { action: "click->ruby-ui--dialog#dismiss" }) { "Cancel" }
              Button(variant: :primary, type: "submit") { @action }
            end
          end
        end

        private

        def render_quantity_field(label:, reference:, name:, receipt_item_id:, initial_quantity:, min:)
          div(class: "space-y-2") do
            render RubyUI::FormField.new do
              div(class: "flex items-center justify-between mb-2") do
                render RubyUI::FormFieldLabel.new { label }
                span(class: "text-xs text-muted-foreground") { reference }
              end
              render RubyUI::Input.new(
                type: :number,
                name: "quantity_#{name}",
                placeholder: "0",
                value: initial_quantity.to_s,
                min: min,
                step: 1,
                required: false,
                data: {
                  receipt_form_target: "#{name}QuantityInput",
                  action: "input->receipt-form#onQuantityChange"
                }
              )
              div(class: "text-xs text-muted-foreground mt-1") do
                span { "Value: " }
                span(
                  data: {
                    receipt_form_target: "#{name}Amount"
                  }
                ) { "EUR 0.00" }
              end
              render RubyUI::FormFieldError.new
            end
          end
        end
      end
    end
  end
end
