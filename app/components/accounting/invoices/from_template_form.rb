module Components
  module Accounting
    module Invoices
      class FromTemplateForm < Components::Base
        def initialize(invoice_template:)
          @invoice_template = invoice_template
          super()
        end

        def view_template
          @user = view_context.current_user
          render RubyUI::Form.new(
            action: view_context.invoices_path,
            method: "post",
            class: "space-y-6",
            data: {
              turbo: true,
              action: "turbo:submit-end@document->ruby-ui--dialog#dismiss"
            }
          ) do
            # Hidden fields for Rails
            input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            input(type: :hidden, name: "invoice[invoice_template_id]", value: @invoice_template.id)
            input(type: :hidden, name: "invoice[provider_id]", value: @invoice_template.provider_address_id)
            input(type: :hidden, name: "invoice[customer_id]", value: @invoice_template.customer_id)
            input(type: :hidden, name: "invoice[currency]", value: @invoice_template.currency)

            # Display template information (read-only)
            div(class: "space-y-4 p-4 bg-muted rounded-md") do
              div(class: "text-sm font-semibold mb-2") { "Template Information" }
              
              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Template Name" }
                div(class: "text-sm text-muted-foreground") { @invoice_template.name }
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Provider" }
                div(class: "text-sm text-muted-foreground") { @invoice_template.provider_address.name }
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Customer" }
                div(class: "text-sm text-muted-foreground") { @invoice_template.customer.name }
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Currency" }
                div(class: "text-sm text-muted-foreground") { @invoice_template.currency }
              end
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Issue Date" }
              render RubyUI::Input.new(
                type: :date,
                name: "invoice[issued_at]",
                id: "invoice_issued_at",
                class: "date-input-icon-light text-primary-foreground",
                value: Date.today.strftime("%Y-%m-%d"),
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
                class: "date-input-icon-light text-primary-foreground"
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
              )
              render RubyUI::FormFieldError.new
            end

            # Invoice Items Section
            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Invoice Items" }
              div(
                class: "space-y-4",
                data: {
                  controller: "invoice-items-form",
                  invoice_items_form_accounting_items_value: accounting_items_json,
                  invoice_items_form_tax_brackets_value: tax_brackets_json,
                  invoice_items_form_currency_value: @invoice_template.currency
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
                    # Items will be added dynamically by JavaScript
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
              Button(variant: :primary, type: "submit") { "Create Invoice" }
            end
          end
        end

        private

        def accounting_items_json
          @user.accounting_items.map do |item|
            [item.id.to_s, {
              id: item.id.to_s,
              name: item.name,
              reference: item.reference,
              # price is stored as integer cents, expose in units for the UI
              price: item.price.to_f / 100.0,
              unit: item.unit
            }]
          end.to_h.to_json
        end

        def tax_brackets_json
          @user.tax_brackets.map do |bracket|
            [bracket.id.to_s, {
              id: bracket.id.to_s,
              name: bracket.name,
              percentage: bracket.percentage.to_f
            }]
          end.to_h.to_json
        end
      end
    end
  end
end