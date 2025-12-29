module Components
  module Accounting
    module Receipts
      class ReceiptItemForm < ::Components::Base
        def initialize(receipt_item: nil)
          @receipt_item = receipt_item || ::Accounting::ReceiptItem.new
          @is_new_record = @receipt_item.nil? || !@receipt_item.persisted?
          @action = @is_new_record ? "Create" : "Update"
          # Set default active to true for new records
          @receipt_item.active = true if @is_new_record && @receipt_item.active.nil?
        end

        def view_template
          form_url = if @is_new_record
            view_context.receipt_items_path
          else
            view_context.receipt_item_path(@receipt_item)
          end

          render RubyUI::Form.new(
            action: form_url,
            method: "post",
            class: "space-y-6",
            data: {
              turbo: true,
              action: "submit->receipt-item-form#submit turbo:submit-end->receipt-item-form#reset turbo:submit-end@document->ruby-ui--dialog#dismiss",
              controller: "receipt-item-form",
              receipt_item_form_tax_brackets_value: tax_brackets_json
            }
          ) do
            # Hidden fields for Rails
            input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            input(type: :hidden, name: "_method", value: "patch") if @receipt_item.persisted?

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Kind" }
              select(
                name: "receipt_item[kind]",
                class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                required: true
              ) do
                ::Accounting::ReceiptItem.kinds.each_key do |kind|
                  option(
                    value: kind,
                    selected: @receipt_item.kind == kind.to_s
                  ) { kind.to_s.humanize }
                end
              end
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Reference" }
              render RubyUI::Input.new(
                type: :text,
                name: "receipt_item[reference]",
                placeholder: "Enter reference",
                value: @receipt_item.reference.to_s,
                required: true
              )
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Description" }
              render RubyUI::Textarea.new(
                name: "receipt_item[description]",
                placeholder: "Enter description",
                rows: 3,
              ) do
                @receipt_item.description.to_s
              end
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Unit" }
              select(
                name: "receipt_item[unit]",
                class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                required: true
              ) do
                ::Accounting::ReceiptItem.units.each_key do |unit|
                  option(
                    value: unit,
                    selected: @receipt_item.unit == unit.to_s
                  ) { unit.to_s.humanize }
                end
              end
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Gross Unit Price" }
              render RubyUI::Input.new(
                type: :number,
                name: "receipt_item[gross_unit_price]",
                id: "receipt_item_gross_unit_price",
                placeholder: "0.00",
                value: gross_unit_price_in_units,
                step: "0.01",
                required: true,
                data: {
                  action: "input->receipt-item-form#calculateUnitPriceWithTax",
                  receipt_item_form_target: "grossUnitPrice"
                }
              )
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Tax Bracket" }
              select(
                name: "receipt_item[tax_bracket_id]",
                id: "receipt_item_tax_bracket_id",
                class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                required: true,
                data: {
                  action: "change->receipt-item-form#onTaxBracketChange input->receipt-item-form#calculateUnitPriceWithTax",
                  receipt_item_form_target: "taxBracket"
                }
              ) do
                option(value: "", selected: @receipt_item.tax_bracket_id.nil?) { "Select a tax bracket" }
                view_context.current_user.tax_brackets.each do |tax_bracket|
                  option(
                    value: tax_bracket.id,
                    selected: @receipt_item.tax_bracket_id == tax_bracket.id
                  ) { "#{tax_bracket.name} (#{tax_bracket.percentage}%)" }
                end
              end
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Exemption Motive" }
              render RubyUI::Input.new(
                type: :text,
                name: "receipt_item[exemption_motive]",
                id: "receipt_item_exemption_motive",
                placeholder: "Enter exemption motive",
                value: @receipt_item.exemption_motive.to_s,
                required: exemption_motive_required?,
                disabled: !exemption_motive_required?,
                data: {
                  receipt_item_form_target: "exemptionMotive"
                }
              )
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Unit Price with Tax" }
              input(
                type: :number,
                name: "receipt_item[unit_price_with_tax]",
                id: "receipt_item_unit_price_with_tax",
                placeholder: "0.00",
                value: unit_price_with_tax_in_units,
                step: "0.01",
                required: true,
                readonly: true,
                class: "flex h-9 w-full rounded-md border bg-muted px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring cursor-not-allowed",
                data: {
                  receipt_item_form_target: "unitPriceWithTax"
                }
              )
              div(class: "text-xs text-muted-foreground mt-1") { "Auto-calculated based on gross unit price and tax bracket" }
              render RubyUI::FormFieldError.new
            end

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Active" }
              div(class: "flex items-center gap-2") do
                # Hidden field to ensure false is sent when unchecked
                input(type: :hidden, name: "receipt_item[active]", value: "false")
                
                label(class: "relative inline-flex items-center cursor-pointer") do
                  input(
                    type: :checkbox,
                    name: "receipt_item[active]",
                    value: "true",
                    class: "sr-only peer",
                    checked: @receipt_item.active != false
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
                span(class: "text-sm text-muted-foreground") { "Item is active" }
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

        def gross_unit_price_in_units
          return "" if @receipt_item.gross_unit_price.nil?
          (@receipt_item.gross_unit_price.to_f / 100.0).to_s
        end

        def unit_price_with_tax_in_units
          return "" if @receipt_item.unit_price_with_tax.nil?
          (@receipt_item.unit_price_with_tax.to_f / 100.0).to_s
        end

        def exemption_motive_required?
          return false if @receipt_item.tax_bracket_id.nil?
          tax_bracket = view_context.current_user.tax_brackets.find_by(id: @receipt_item.tax_bracket_id)
          tax_bracket.present? && tax_bracket.percentage == 0
        end

        def tax_brackets_json
          view_context.current_user.tax_brackets.map do |bracket|
            [bracket.id.to_s, {
              id: bracket.id.to_s,
              percentage: bracket.percentage.to_f
            }]
          end.to_h.to_json
        end
      end
    end
  end
end