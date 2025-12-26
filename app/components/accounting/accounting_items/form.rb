module Components
  module Accounting
    module AccountingItems
      class Form < Components::Base
        def initialize(accounting_item: nil)
          @accounting_item = accounting_item || ::Accounting::AccountingItem.new
          @is_new_record = @accounting_item.new_record?
          @action = @is_new_record ? "Create" : "Update"
          super(**attrs)
        end

        def view_template
          form_url = if @is_new_record
            view_context.accounting_items_path
          else
            view_context.accounting_item_path(@accounting_item)
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
              render RubyUI::FormFieldLabel.new { "Reference" }
              render RubyUI::Input.new(
                type: :text,
                name: "accounting_item[reference]",
                placeholder: "Enter reference",
                value: @accounting_item.reference.to_s,
                required: true
              )
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Name" }
              render RubyUI::Input.new(
                type: :text,
                name: "accounting_item[name]",
                placeholder: "Enter name",
                value: @accounting_item.name.to_s,
                required: true
              )
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Kind" }
              select(
                name: "accounting_item[kind]",
                class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                required: true
              ) do
                ::Accounting::AccountingItem.kinds.each_key do |kind|
                  option(
                    value: kind,
                    selected: @accounting_item.kind == kind.to_s
                  ) { kind.to_s.humanize }
                end
              end
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Description" }
              render RubyUI::Textarea.new(
                name: "accounting_item[description]",
                placeholder: "Enter description",
                rows: 3,
              ) do
                @accounting_item.description.to_s
              end

              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Unit" }
              render RubyUI::Input.new(
                type: :text,
                name: "accounting_item[unit]",
                placeholder: "e.g., hour, piece, kg",
                value: @accounting_item.unit.to_s,
                required: true
              )
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Price" }
              render RubyUI::Input.new(
                type: :number,
                name: "accounting_item[price]",
                placeholder: "0.00",
                value: price_in_units,
                step: "0.01",
                required: true
              )
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Currency" }
              select(
                name: "accounting_item[currency]",
                class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                required: true
              ) do
                ::Accounting::AccountingItem.currencies.each_key do |currency|
                  option(
                    value: currency,
                    selected: @accounting_item.currency == currency.to_s
                  ) { currency.to_s }
                end
              end
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Convert Currency" }
              div(class: "flex items-center gap-2") do
                # Hidden field to ensure false is sent when unchecked
                input(type: :hidden, name: "accounting_item[convert_currency]", value: "false")
                
                label(class: "relative inline-flex items-center cursor-pointer") do
                  input(
                    type: :checkbox,
                    name: "accounting_item[convert_currency]",
                    value: "true",
                    class: "sr-only peer",
                    checked: @accounting_item.convert_currency
                  )
                  div(
                    class: [
                      "w-11 h-6 bg-input rounded-full peer",
                      "peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-ring peer-focus:ring-offset-2",
                      "peer-checked:after:translate-x-full",
                      "after:content-[''] after:absolute after:top-0.5 after:left-[2px]",
                      "after:bg-background after:rounded-full after:h-5 after:w-5",
                      "after:transition-all peer-checked:bg-primary"
                    ]
                  )
                end
                span(class: "text-sm text-muted-foreground") { "Enable currency conversion" }
              end
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Detail" }
              render RubyUI::Textarea.new(
                name: "accounting_item[detail]",
                placeholder: "Enter additional details",
                rows: 3,
              ) do
                @accounting_item.detail.to_s
              end

              render RubyUI::FormFieldError.new
            end

            div(class: "flex gap-2 justify-end") do
              Button(variant: :outline, type: "button", data: { action: "click->ruby-ui--dialog#dismiss" }) { "Cancel" }
              Button(variant: :primary, type: "submit") { @action }
            end
          end
        end

        private

        def price_in_units
          return "" if @accounting_item.price.nil?
          (@accounting_item.price.to_f / 100.0).to_s
        end
      end
    end
  end
end