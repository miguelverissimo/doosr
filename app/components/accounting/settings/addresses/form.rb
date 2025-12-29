module Components
  module Accounting
    module Settings
      module Addresses
        class Form < ::Components::Base
          def initialize(address: nil)
            @address = address || ::Address.new(address_type: :user)
            @is_new_record = @address.new_record?
            @action = @is_new_record ? "Create" : "Update"
            super(**attrs)
          end

          def view_template
            form_url = if @is_new_record
              view_context.settings_addresses_path
            else
              view_context.settings_address_path(@address)
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
                  name: "address[name]",
                  placeholder: "Enter name",
                  value: @address.name.to_s,
                  required: true
                )
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Full Address" }
                render RubyUI::Textarea.new(
                  name: "address[full_address]",
                  placeholder: "Enter full address",
                  rows: 5,
                  required: true
                ) do
                  @address.full_address.to_s
                end
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Country" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "address[country]",
                  placeholder: "Enter country",
                  value: @address.country.to_s,
                  required: true
                )
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Fiscal Number (Optional)" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "address[fiscal_number]",
                  placeholder: "Enter fiscal/tax number",
                  value: @address.fiscal_info&.tax_number.to_s
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