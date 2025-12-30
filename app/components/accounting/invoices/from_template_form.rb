module Components
  module Accounting
    module Invoices
      class FromTemplateForm < ::Components::Base
        def initialize(user:)
          @user = user
          super()
        end

        def view_template
          render RubyUI::Form.new(
            action: view_context.invoices_path,
            method: "post",
            class: "space-y-6",
            data: {
              turbo: true,
              controller: "invoice-date-constraint invoice-template-selector invoice-number-validator modal-form",
              invoice_template_selector_templates_value: templates_data_json,
              modal_form_loading_message_value: "Creating invoice from template...",
              modal_form_success_message_value: "Invoice created successfully"
            }
          ) do
            # Hidden fields for Rails
            input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            input(
              type: :hidden,
              name: "invoice[provider_id]",
              data: { invoice_template_selector_target: "providerId" }
            )
            input(
              type: :hidden,
              name: "invoice[customer_id]",
              data: { invoice_template_selector_target: "customerId" }
            )
            input(
              type: :hidden,
              name: "invoice[currency]",
              data: { invoice_template_selector_target: "currencyField" }
            )

            # Template selector
            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Select Template" }
              select(
                name: "invoice[invoice_template_id]",
                id: "invoice_template_id",
                class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                required: true,
                data: {
                  action: "change->invoice-template-selector#loadTemplate",
                  invoice_template_selector_target: "templateSelect"
                }
              ) do
                option(value: "") { "Select a template" }
                @user.invoice_templates.each do |template|
                  option(value: template.id) { template.name }
                end
              end
              render RubyUI::FormFieldError.new
            end

            # Template information (populated by JS)
            div(
              class: "hidden space-y-4 p-4 bg-muted rounded-md",
              data: { invoice_template_selector_target: "templateInfo" }
            ) do
              div(class: "text-sm font-semibold mb-2") { "Template Information" }

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Provider" }
                div(
                  class: "text-sm text-muted-foreground",
                  data: { invoice_template_selector_target: "provider" }
                ) { "" }
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Customer" }
                div(
                  class: "text-sm text-muted-foreground",
                  data: { invoice_template_selector_target: "customer" }
                ) { "" }
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Currency" }
                div(
                  class: "text-sm text-muted-foreground",
                  data: { invoice_template_selector_target: "currency" }
                ) { "" }
              end
            end

            # Invoice number and customer reference row
            div(class: "flex flex-row items-start gap-4") do
              div(class: "flex-1") do
                render RubyUI::FormField.new do
                  render RubyUI::FormFieldLabel.new { "Invoice Number" }
                  input(
                    type: :number,
                    name: "invoice[number]",
                    id: "invoice_number",
                    min: 1,
                    required: true,
                    class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                    data: {
                      invoice_number_validator_target: "numberInput",
                      action: "blur->invoice-number-validator#validateNumber"
                    }
                  )
                  div(
                    class: "hidden text-sm text-red-500 mt-1",
                    data: { invoice_number_validator_target: "errorMessage" }
                  ) { "" }
                end
              end

              div(class: "flex-1") do
                render RubyUI::FormField.new do
                  render RubyUI::FormFieldLabel.new { "Customer Reference" }
                  render RubyUI::Input.new(
                    type: :text,
                    name: "invoice[customer_reference]",
                    id: "invoice_customer_reference",
                    placeholder: "Enter customer reference"
                  )
                  render RubyUI::FormFieldError.new
                end
              end
            end

            # Issue date and due date row
            div(class: "flex flex-row items-start gap-4") do
              div(class: "flex-1") do
                render RubyUI::FormField.new do
                  render RubyUI::FormFieldLabel.new { "Issue Date" }
                  input(
                    type: :date,
                    name: "invoice[issued_at]",
                    id: "invoice_issued_at",
                    class: "date-input-icon-light text-primary-foreground flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                    value: Date.today.strftime("%Y-%m-%d"),
                    required: true,
                    data: {
                      invoice_number_validator_target: "issueDateInput",
                      action: "change->invoice-date-constraint#updateDueDateMin change->invoice-number-validator#validateNumber"
                    }
                  )
                  render RubyUI::FormFieldError.new
                end
              end

              div(class: "flex-1") do
                render RubyUI::FormField.new do
                  render RubyUI::FormFieldLabel.new { "Due Date" }
                  issue_date_value = Date.today.strftime("%Y-%m-%d")
                  default_due_date = Date.today.end_of_month.strftime("%Y-%m-%d")
                  render RubyUI::Input.new(
                    type: :date,
                    name: "invoice[due_at]",
                    id: "invoice_due_at",
                    class: "date-input-icon-light text-primary-foreground",
                    value: default_due_date,
                    min: issue_date_value,
                    required: true,
                    data: {
                      invoice_date_constraint_target: "dueDate"
                    }
                  )
                  render RubyUI::FormFieldError.new
                end
              end
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
                  invoice_items_form_currency_value: "eur",
                  invoice_items_form_initial_items_value: "[]",
                  invoice_template_selector_target: "itemsForm"
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
                    variant: :secondary,
                    size: :sm,
                    data: {
                      action: "click->invoice-items-form#addItem"
                    }
                  ) { "Add Item" }
                end
              end
              render RubyUI::FormFieldError.new
            end

            div(class: "flex flex-row gap-2 justify-between items-baseline border-t border-border mt-4 pt-4") do
              # Invoice Total
              div(
                class: "flex justify-start",
                data: { invoice_items_form_target: "invoiceTotalContainer" }
              ) do
                div(class: "text-xl font-bold") do
                  span(class: "text-muted-foreground") { "Total: " }
                  span(
                    id: "invoice_total_display",
                    class: "ml-2",
                    data: { invoice_items_form_target: "invoiceTotalDisplay" }
                  ) { "" }
                end
              end

              div(class: "flex gap-2 justify-end") do
                Button(variant: :outline, type: "button", data: { action: "click->ruby-ui--dialog#dismiss" }) { "Cancel" }
                Button(
                  variant: :primary,
                  type: "submit",
                  data: { invoice_number_validator_target: "submitButton" }
                ) { "Create Invoice" }
              end
            end
          end
        end

        private

        def accounting_items_json
          @user.accounting_items.map do |item|
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
          @user.tax_brackets.map do |bracket|
            [ bracket.id.to_s, {
              id: bracket.id.to_s,
              name: bracket.name,
              percentage: bracket.percentage.to_f
            } ]
          end.to_h.to_json
        end

        def templates_data_json
          @user.invoice_templates.includes(:provider_address, :customer, :invoice_template_items).map do |template|
            {
              id: template.id.to_s,
              name: template.name,
              provider_name: template.provider_address.name,
              customer_name: template.customer.name,
              currency: template.currency,
              provider_id: template.provider_address_id.to_s,
              customer_id: template.customer_id.to_s,
              items: template.invoice_template_items.map do |item|
                {
                  item_id: item.item_id.to_s,
                  quantity: item.quantity.to_f,
                  discount_rate: item.discount_rate.to_f,
                  tax_bracket_id: item.tax_bracket_id.to_s,
                  description: item.description.to_s,
                  unit: item.unit.to_s
                }
              end
            }
          end.to_json
        end
      end
    end
  end
end
