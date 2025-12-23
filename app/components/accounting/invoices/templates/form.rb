module Components
  module Accounting
    module Invoices
      module Templates
        class Form < Components::Base
          def initialize(invoice_template: nil, user: nil, **attrs)
            @invoice_template = invoice_template || ::Accounting::InvoiceTemplate.new
            @user = user
            @is_new_record = @invoice_template.new_record?
            @action = @is_new_record ? "Create" : "Update"
            super(**attrs)
          end

          def view_template
            form_url = if @is_new_record
              view_context.invoice_templates_path
            else
              view_context.invoice_template_path(@invoice_template)
            end

            render RubyUI::Form.new(
              action: form_url,
              method: "post",
              class: "space-y-6",
              data: {
                turbo: true,
                action: "turbo:submit-end@document->ruby-ui--dialog#dismiss"
              }
            ) do
              # Hidden fields for Rails
              input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
              input(type: :hidden, name: "_method", value: "patch") unless @is_new_record

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Name" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "invoice_template[name]",
                  id: "invoice_template_name",
                  placeholder: "Enter invoice template name",
                  value: @invoice_template.name.to_s,
                  required: true
                )
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Description" }
                render RubyUI::Textarea.new(
                  name: "invoice_template[description]",
                  id: "invoice_template_description",
                  placeholder: "Enter description",
                  rows: 3,
                  required: true
                ) do
                  @invoice_template.description.to_s
                end
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Logo" }
                select(
                  name: "invoice_template[accounting_logo_id]",
                  id: "invoice_template_accounting_logo_id",
                  class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                  required: true
                ) do
                  option(value: "", selected: @invoice_template.accounting_logo_id.nil?) { "Select a logo" }
                  user.accounting_logos.each do |logo|
                    option(
                      value: logo.id,
                      selected: @invoice_template.accounting_logo_id == logo.id
                    ) { logo.title }
                  end
                end
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Provider Address" }
                select(
                  name: "invoice_template[provider_address_id]",
                  id: "invoice_template_provider_address_id",
                  class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                  required: true
                ) do
                  option(value: "", selected: @invoice_template.provider_address_id.nil?) { "Select an address" }
                  user.addresses.user.active.each do |address|
                    option(
                      value: address.id,
                      selected: @invoice_template.provider_address_id == address.id
                    ) { address.name }
                  end
                end
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Customer" }
                select(
                  name: "invoice_template[customer_id]",
                  id: "invoice_template_customer_id",
                  class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                  required: true
                ) do
                  option(value: "", selected: @invoice_template.customer_id.nil?) { "Select a customer" }
                  user.customers.each do |customer|
                    option(
                      value: customer.id,
                      selected: @invoice_template.customer_id == customer.id
                    ) { customer.name }
                  end
                end
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Currency" }
                select(
                  name: "invoice_template[currency]",
                  id: "invoice_template_currency",
                  class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                  required: true
                ) do
                  ::Accounting::InvoiceTemplate.currencies.each_key do |currency|
                    option(
                      value: currency,
                      selected: @invoice_template.currency == currency.to_s
                    ) { currency }
                  end
                end
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Bank Info (Optional)" }
                select(
                  name: "invoice_template[bank_info_id]",
                  id: "invoice_template_bank_info_id",
                  class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                ) do
                  option(value: "", selected: @invoice_template.bank_info_id.nil?) { "Select bank info (optional)" }
                  user.bank_infos.where(kind: :user).each do |bank_info|
                    option(
                      value: bank_info.id,
                      selected: @invoice_template.bank_info_id == bank_info.id
                    ) { bank_info.name }
                  end
                end
                render RubyUI::FormFieldError.new
              end

              # Invoice Template Items Section
              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Template Items" }
                div(
                  class: "space-y-4",
                  data: {
                    controller: "invoice-items-form",
                    invoice_items_form_accounting_items_value: accounting_items_json,
                    invoice_items_form_tax_brackets_value: tax_brackets_json,
                    invoice_items_form_currency_value: @invoice_template.currency || "EUR",
                    invoice_items_form_initial_items_value: initial_template_items_json,
                    invoice_items_form_form_prefix_value: "invoice_template[invoice_template_items_attributes]"
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

              render RubyUI::Button.new(variant: :primary, type: :submit) { @action }
            end
          end

          private

          def user
            @user || view_context.current_user
          end

          def accounting_items_json
            user.accounting_items.map do |item|
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
            user.tax_brackets.map do |bracket|
              [bracket.id.to_s, {
                id: bracket.id.to_s,
                name: bracket.name,
                percentage: bracket.percentage.to_f
              }]
            end.to_h.to_json
          end

          def initial_template_items_json
            return [].to_json if @invoice_template.new_record? || @invoice_template.invoice_template_items.empty?

            @invoice_template.invoice_template_items.map do |item|
              {
                item_id: item.item_id.to_s,
                quantity: item.quantity.to_f,
                discount_rate: item.discount_rate.to_f,
                tax_bracket_id: item.tax_bracket_id.to_s,
                description: item.description.to_s,
                unit: item.unit.to_s
              }
            end.to_json
          end
        end
      end
    end
  end
end
