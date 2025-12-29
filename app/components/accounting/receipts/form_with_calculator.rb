module Components
  module Accounting
    module Receipts
      class FormWithCalculator < ::Components::Base
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

          render RubyUI::Form.new(
            action: form_url,
            method: "post",
            enctype: "multipart/form-data",
            class: "space-y-6",
            data: {
              turbo: true,
              action: "turbo:submit-end@document->ruby-ui--dialog#dismiss",
              controller: "receipt-calculator form-loading payment-type-toggle",
              receipt_calculator_manev_h_unit_price_value: manev_h_item&.unit_price_with_tax || 0,
              receipt_calculator_manev_on_call_unit_price_value: manev_on_call_item&.unit_price_with_tax || 0,
              receipt_calculator_token_unit_price_value: token_item&.unit_price_with_tax || 0,
              form_loading_message_value: "Creating receipt..."
            }
          ) do
            # Hidden fields for Rails
            input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            input(type: :hidden, name: "_method", value: "patch") unless @is_new_record

            # Calculator section
            div(class: "space-y-6") do
              div(class: "p-4 border rounded-lg bg-muted/50") do
                h3(class: "text-lg font-semibold mb-4") { "Calculator" }

              # Value input field - always show
              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Receipt Value" }
                render RubyUI::Input.new(
                  type: :number,
                  name: "receipt[value]",
                  placeholder: "0.00",
                  value: @receipt&.value_in_units&.to_s || "",
                  step: "0.01",
                  required: true,
                  data: {
                    receipt_calculator_target: "valueInput",
                    action: "input->receipt-calculator#onValueChange"
                  }
                )
                render RubyUI::FormFieldError.new
              end

              # Show message if ReceiptItems are missing
              unless manev_h_item && manev_on_call_item && token_item
                div(class: "p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-md") do
                  p(class: "text-sm text-yellow-800 dark:text-yellow-200") do
                    "Please create the required ReceiptItems first: OUT - MANEV-H, OUT - MANEV-ON-CALL, and OUT - TOKEN"
                  end
                end
              end

              # OUT - MANEV-H slider
              if manev_h_item
                render_range_field(
                  label: manev_h_item.description,
                  reference: "OUT - MANEV-H",
                  min: 110,
                  max: 176,
                  unit_price: manev_h_item.unit_price_with_tax,
                  receipt_item_id: manev_h_item.id,
                  target: "manevHSlider",
                  action: "input->receipt-calculator#onManevHChange",
                  display_target: "manevHDisplay",
                  amount_target: "manevHAmount"
                )
              end

              # OUT - MANEV-ON-CALL slider
              if manev_on_call_item
                render_range_field(
                  label: manev_on_call_item.description,
                  reference: "OUT - MANEV-ON-CALL",
                  min: 1,
                  max: 1000, # Will be dynamically adjusted by Stimulus
                  unit_price: manev_on_call_item.unit_price_with_tax,
                  receipt_item_id: manev_on_call_item.id,
                  target: "manevOnCallSlider",
                  action: "input->receipt-calculator#onManevOnCallChange",
                  display_target: "manevOnCallDisplay",
                  amount_target: "manevOnCallAmount"
                )
              end

              # OUT - TOKEN display (non-interactive)
              if token_item
                div(class: "space-y-2") do
                  div(class: "flex items-center justify-between") do
                    label(class: "text-sm font-medium") { token_item.description }
                    span(class: "text-xs text-muted-foreground") { "OUT - TOKEN" }
                  end
                  div(class: "flex items-center gap-4") do
                    input(
                      type: :range,
                      min: 0,
                      max: 100000,
                      value: 0,
                      disabled: true,
                      class: "flex-1 h-2 bg-input rounded-lg appearance-none cursor-not-allowed opacity-50",
                      data: {
                        receipt_calculator_target: "tokenSlider",
                        receipt_item_id: token_item.id
                      }
                    )
                    div(class: "flex flex-col items-end min-w-[120px]") do
                      span(
                        class: "text-sm font-semibold",
                        data: {
                          receipt_calculator_target: "tokenDisplay"
                        }
                      ) { "0" }
                      span(
                        class: "text-xs text-muted-foreground",
                        data: {
                          receipt_calculator_target: "tokenAmount"
                        }
                      ) { "EUR 0.00" }
                    end
                  end
                end
              end

              # Total display
              div(class: "pt-4 border-t") do
                div(class: "flex items-center justify-between") do
                  span(class: "text-sm font-medium") { "Total" }
                  span(
                    class: "text-lg font-semibold",
                    data: {
                      receipt_calculator_target: "totalDisplay"
                    }
                  ) { "EUR 0.00" }
                end
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

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Document (PDF)" }
                if @receipt&.document&.attached?
                  div(class: "mb-2 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-md") do
                    p(class: "text-sm text-yellow-800 dark:text-yellow-200") do
                      plain "Current file: "
                      strong { @receipt.document.filename.to_s }
                      plain " - Uploading a new file will replace this one."
                    end
                  end
                end
                render RubyUI::Input.new(
                  type: :file,
                  name: "receipt[document]",
                  accept: "application/pdf"
                )
                p(class: "text-sm text-muted-foreground mt-1") { "Upload a PDF document (max 10MB)" }
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
                        id: "payment_type_total_calc",
                        value: "total",
                        checked: current_payment_type == "total"
                      )
                      render RubyUI::FormFieldLabel.new(for: "payment_type_total_calc") { "Total Payment" }
                    end
                    div(class: "flex items-center space-x-2") do
                      render RubyUI::RadioButton.new(
                        name: "receipt[payment_type]",
                        id: "payment_type_partial_calc",
                        value: "partial",
                        checked: current_payment_type == "partial"
                      )
                      render RubyUI::FormFieldLabel.new(for: "payment_type_partial_calc") { "Partial Payment" }
                    end
                  end
                end

                # Switch to mark invoice as fully paid (checked and disabled when total is selected)
                div(
                  id: "mark_fully_paid_container_calc",
                  data: { payment_type_toggle_target: "container" }
                ) do
                  render RubyUI::FormField.new do
                    div(class: "flex items-center gap-2") do
                      render RubyUI::Switch.new(
                        name: "mark_fully_paid",
                        id: "mark_fully_paid_calc",
                        checked: @receipt&.completes_payment || current_payment_type == "total",
                        disabled: current_payment_type == "total",
                        data: { payment_type_toggle_target: "switch" }
                      )
                      label(for: "mark_fully_paid_calc", class: "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70") do
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
                data: { receipt_calculator_target: "manevHReceiptItemId" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][0][quantity]",
                value: "110",
                data: { receipt_calculator_target: "manevHQuantity" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][0][value_with_tax]",
                value: "0",
                data: { receipt_calculator_target: "manevHValueWithTax" }
              )
            end

            if manev_on_call_item
              input(
                type: :hidden,
                name: "receipt[items_attributes][1][receipt_item_id]",
                value: manev_on_call_item.id,
                data: { receipt_calculator_target: "manevOnCallReceiptItemId" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][1][quantity]",
                value: "1",
                data: { receipt_calculator_target: "manevOnCallQuantity" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][1][value_with_tax]",
                value: "0",
                data: { receipt_calculator_target: "manevOnCallValueWithTax" }
              )
            end

            if token_item
              input(
                type: :hidden,
                name: "receipt[items_attributes][2][receipt_item_id]",
                value: token_item.id,
                data: { receipt_calculator_target: "tokenReceiptItemId" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][2][quantity]",
                value: "0",
                data: { receipt_calculator_target: "tokenQuantity" }
              )
              input(
                type: :hidden,
                name: "receipt[items_attributes][2][value_with_tax]",
                value: "0",
                data: { receipt_calculator_target: "tokenValueWithTax" }
              )
            end

            div(class: "flex gap-2 justify-end mt-6") do
              Button(variant: :outline, type: "button", data: { action: "click->ruby-ui--dialog#dismiss" }) { "Cancel" }
              Button(variant: :primary, type: "submit") { @action }
            end
          end
        end

        private

        def render_range_field(label:, reference:, min:, max:, unit_price:, receipt_item_id:, target:, action:, display_target:, amount_target:)
          div(class: "space-y-2") do
            div(class: "flex items-center justify-between") do
              label(class: "text-sm font-medium") { label }
              span(class: "text-xs text-muted-foreground") { reference }
            end
            div(class: "flex items-center gap-4") do
              input(
                type: :range,
                min: min,
                max: max,
                value: min,
                step: 1,
                class: "flex-1 h-2 bg-input rounded-lg appearance-none cursor-pointer accent-primary",
                style: "background: linear-gradient(to right, hsl(var(--primary)) 0%, hsl(var(--primary)) var(--value-percent, 0%), hsl(var(--input)) var(--value-percent, 0%), hsl(var(--input)) 100%)",
                data: {
                  receipt_calculator_target: target,
                  action: action,
                  receipt_item_id: receipt_item_id
                }
              )
              div(class: "flex flex-col items-end min-w-[120px]") do
                span(
                  class: "text-sm font-semibold",
                  data: {
                    receipt_calculator_target: display_target
                  }
                ) { min.to_s }
                span(
                  class: "text-xs text-muted-foreground",
                  data: {
                    receipt_calculator_target: amount_target
                  }
                ) { "EUR 0.00" }
              end
            end
          end
        end
      end
    end
  end
end
