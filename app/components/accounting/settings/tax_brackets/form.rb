module Components
  module Accounting
    module Settings
      module TaxBrackets
        class Form < Components::Base
          def initialize(tax_bracket: nil)
            @tax_bracket = tax_bracket || ::Accounting::TaxBracket.new
            @is_new_record = @tax_bracket.new_record?
            @action = @is_new_record ? "Create" : "Update"
            super(**attrs)
          end

          def view_template
            form_url = if @is_new_record
              view_context.settings_tax_brackets_path
            else
              view_context.settings_tax_bracket_path(@tax_bracket)
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
                  name: "tax_bracket[name]",
                  placeholder: "Enter name",
                  value: @tax_bracket.name.to_s,
                  required: true
                )
              render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Percentage" }
                render RubyUI::Input.new(
                  type: :number,
                  name: "tax_bracket[percentage]",
                  placeholder: "0.00",
                  value: @tax_bracket.percentage&.to_f&.to_s,
                  step: "0.01",
                  required: true
                )
              render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Legal Reference" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "tax_bracket[legal_reference]",
                  placeholder: "Enter legal reference",
                  value: @tax_bracket.legal_reference.to_s
                )
              render RubyUI::FormFieldError.new
              end

              div(class: "flex gap-2 justify-end") do
                Button(variant: :outline, type: "button", data: { action: "click->ruby-ui--dialog#dismiss" }) { "Cancel" }
                Button(variant: :primary, type: "submit") { @action }
              end
            end
          end
        end  
      end
    end
  end
end