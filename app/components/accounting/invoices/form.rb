module Components
  module Accounting
    module Invoices
      class Form < Components::Base
        def initialize(invoice:)
          @invoice = invoice
          super()
        end

        def view_template
          @user = view_context.current_user
          render RubyUI::Form.new(
            action: view_context.invoice_path(@invoice),
            method: "post",
            class: "space-y-6",
            data: {
              turbo: true,
              action: "turbo:submit-end@document->ruby-ui--dialog#dismiss"
            }
          ) do
            # Hidden fields for Rails
            input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            input(type: :hidden, name: "_method", value: "patch")

            # Basic invoice attributes
            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Invoice Number" }
              render RubyUI::Input.new(
                type: :number,
                name: "invoice[number]",
                id: "invoice_number",
                value: @invoice.number,
                min: 1,
                class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
              )
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Provider" }
              select(
                name: "invoice[provider_id]",
                id: "invoice_provider_id",
                class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                required: true
              ) do
                option(value: "", selected: @invoice.provider_id.nil?) { "Select a provider" }
                user.addresses.each do |address|
                  option(
                    value: address.id,
                    selected: @invoice.provider_id == address.id
                  ) { address.name }
                end
              end
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Customer" }
              select(
                name: "invoice[customer_id]",
                id: "invoice_customer_id",
                class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                required: true
              ) do
                option(value: "", selected: @invoice.customer_id.nil?) { "Select a customer" }
                user.customers.each do |customer|
                  option(
                    value: customer.id,
                    selected: @invoice.customer_id == customer.id
                  ) { customer.name }
                end
              end
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Currency" }
              select(
                name: "invoice[currency]",
                id: "invoice_currency",
                class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                required: true
              ) do
                ::Accounting::Invoice.currencies.each_key do |currency|
                  option(
                    value: currency,
                    selected: @invoice.currency == currency.to_s
                  ) { currency }
                end
              end
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Bank Info (Optional)" }
              select(
                name: "invoice[bank_info_id]",
                id: "invoice_bank_info_id",
                class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
              ) do
                option(value: "", selected: @invoice.bank_info_id.nil?) { "Select bank info (optional)" }
                user.bank_infos.where(kind: :user).each do |bank_info|
                  option(
                    value: bank_info.id,
                    selected: @invoice.bank_info_id == bank_info.id
                  ) { bank_info.name }
                end
              end
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Issue Date" }
              render RubyUI::Input.new(
                type: :date,
                name: "invoice[issued_at]",
                id: "invoice_issued_at",
                class: "date-input-icon-light text-primary-foreground",
                value: (@invoice.issued_at || Date.today).strftime("%Y-%m-%d"),
                required: true
              )
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Due Date" }
              render RubyUI::Input.new(
                type: :date,
                name: "invoice[due_at]",
                id: "invoice_due_at",
                class: "date-input-icon-light text-primary-foreground",
                value: @invoice.due_at&.strftime("%Y-%m-%d")
              )
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Customer Reference" }
              render RubyUI::Input.new(
                type: :text,
                name: "invoice[customer_reference]",
                id: "invoice_customer_reference",
                value: @invoice.customer_reference,
                placeholder: "Enter customer reference"
              )
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Notes" }
              render RubyUI::Textarea.new(
                name: "invoice[notes]",
                id: "invoice_notes",
                placeholder: "Enter additional notes",
                rows: 4
              ) do
                @invoice.notes.to_s
              end
              render RubyUI::FormFieldError.new
            end

            # Invoice Items Section (editable, same UI as creation form)
            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Invoice Items" }
              div(
                class: "space-y-4",
                data: {
                  controller: "invoice-items-form",
                  invoice_items_form_accounting_items_value: accounting_items_json,
                  invoice_items_form_tax_brackets_value: tax_brackets_json,
                  invoice_items_form_currency_value: @invoice.currency,
                  invoice_items_form_initial_items_value: invoice_items_json
                }
              ) do
                div(
                  class: "space-y-4",
                  data: {
                    invoice_items_form_target: "itemsContainer"
                  }
                ) do
                  div(
                    class: "space-y-4",
                    data: {
                      invoice_items_form_target: "itemsList"
                    }
                  ) do
                    # Items will be managed dynamically by JavaScript
                  end

                  Button(
                    type: :button,
                    variant: :outline,
                    size: :sm,
                    data: {
                      action: "click->invoice-items-form#addItem"
                    }
                  ) { "Add Item" }
                end
              end
              render RubyUI::FormFieldError.new
            end

            div(class: "flex gap-2 justify-end") do
              Button(variant: :outline, type: "button", data: { action: "click->ruby-ui--dialog#dismiss" }) { "Cancel" }
              Button(variant: :primary, type: "submit") { "Save Changes" }
            end
          end
        end

        private

        def user
          @user || view_context.current_user
        end

        def accounting_items_json
          user.accounting_items.map do |item|
            [ item.id.to_s, {
              id: item.id.to_s,
              name: item.name,
              reference: item.reference,
              # price is stored as integer cents, expose in units for the UI
              price: item.price.to_f / 100.0,
              unit: item.unit
            } ]
          end.to_h.to_json
        end

        def tax_brackets_json
          user.tax_brackets.map do |bracket|
            [ bracket.id.to_s, {
              id: bracket.id.to_s,
              name: bracket.name,
              percentage: bracket.percentage.to_f
            } ]
          end.to_h.to_json
        end

        def invoice_items_json
          @invoice.invoice_items.map do |invoice_item|
            {
              item_id: invoice_item.item_id,
              quantity: invoice_item.quantity,
              discount_rate: invoice_item.discount_rate,
              tax_bracket_id: invoice_item.tax_bracket_id,
              description: invoice_item.description,
              unit: invoice_item.unit
            }
          end.to_json
        end
      end
    end
  end
end
