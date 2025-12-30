module Components
  module Accounting
    module Customers
      class Form < ::Components::Base
        def initialize(customer: nil)
          @customer = customer || ::Accounting::Customer.new
          @is_new_record = @customer.new_record?
          @action = @is_new_record ? "Create" : "Update"
          super()
        end

        def view_template
          form_url = if @is_new_record
            view_context.customers_path
          else
            view_context.customer_path(@customer)
          end

          # Get existing address if editing
          existing_address = @customer.address

          render RubyUI::Form.new(
            action: form_url,
            method: "post",
            class: "space-y-6",
            data: {
              turbo: true,
              controller: "modal-form",
              modal_form_loading_message_value: (@is_new_record ? "Creating customer..." : "Updating customer..."),
              modal_form_success_message_value: (@is_new_record ? "Customer created successfully" : "Customer updated successfully")
            }
          ) do
            # Hidden fields for Rails
            input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            input(type: :hidden, name: "_method", value: "patch") unless @is_new_record

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Name" }
              render RubyUI::Input.new(
                type: :text,
                name: "customer[name]",
                id: "customer_name",
                placeholder: "Enter customer name",
                value: @customer.name.to_s,
                required: true
              )
              render RubyUI::FormFieldError.new
            end

            div(class: "space-y-4") do
              # Hidden field: address name will be synced with customer name in the controller
              input(
                type: :hidden,
                name: "address[name]",
                id: "address_name",
                value: @customer.name.to_s
              )

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Full Address" }
                render RubyUI::Textarea.new(
                  name: "address[full_address]",
                  placeholder: "Enter full address",
                  rows: 5,
                  required: true
                ) do
                  existing_address&.full_address.to_s
                end
                render RubyUI::FormFieldError.new
              end

              div(class: "flex flex-row gap-4") do
                div(class: "flex-1") do
                  render RubyUI::FormField.new do
                    render RubyUI::FormFieldLabel.new { "Country" }
                    render RubyUI::Input.new(
                      type: :text,
                      name: "address[country]",
                      placeholder: "Enter country",
                      value: existing_address&.country.to_s,
                      required: true
                    )
                    render RubyUI::FormFieldError.new
                  end
                end

                div(class: "flex-1") do
                  render RubyUI::FormField.new do
                    render RubyUI::FormFieldLabel.new { "Telephone" }
                    render RubyUI::Input.new(
                      type: :tel,
                      name: "customer[telephone]",
                      placeholder: "Enter telephone number",
                      value: @customer.telephone.to_s
                    )
                    render RubyUI::FormFieldError.new
                  end
                end
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Fiscal Number (Optional)" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "address[fiscal_number]",
                  placeholder: "Enter fiscal/tax number",
                  value: existing_address&.fiscal_info&.tax_number.to_s
                )
                render RubyUI::FormFieldError.new
              end
            end


            div(class: "space-y-4") do
              div(class: "flex flex-row gap-4") do
                div(class: "flex-1 space-y-4") do
                  render RubyUI::FormField.new do
                    render RubyUI::FormFieldLabel.new { "Contact Name" }
                    render RubyUI::Input.new(
                      type: :text,
                      name: "customer[contact_name]",
                      placeholder: "Enter contact name",
                      value: @customer.contact_name.to_s
                    )
                    render RubyUI::FormFieldError.new
                  end

                  render RubyUI::FormField.new do
                    render RubyUI::FormFieldLabel.new { "Contact Email" }
                    render RubyUI::Input.new(
                      type: :email,
                      name: "customer[contact_email]",
                      placeholder: "Enter contact email",
                      value: @customer.contact_email.to_s
                    )
                    render RubyUI::FormFieldError.new
                  end

                  render RubyUI::FormField.new do
                    render RubyUI::FormFieldLabel.new { "Contact Phone" }
                    render RubyUI::Input.new(
                      type: :tel,
                      name: "customer[contact_phone]",
                      placeholder: "Enter contact phone",
                      value: @customer.contact_phone.to_s
                    )
                    render RubyUI::FormFieldError.new
                  end
                end

                div(class: "flex-1 space-y-4") do
                  render RubyUI::FormField.new do
                    render RubyUI::FormFieldLabel.new { "Billing Contact Name" }
                    render RubyUI::Input.new(
                      type: :text,
                      name: "customer[billing_contact_name]",
                      placeholder: "Enter billing contact name",
                      value: @customer.billing_contact_name.to_s
                    )
                    render RubyUI::FormFieldError.new
                  end

                  render RubyUI::FormField.new do
                    render RubyUI::FormFieldLabel.new { "Billing Email" }
                    render RubyUI::Input.new(
                      type: :email,
                      name: "customer[billing_email]",
                      placeholder: "Enter billing email",
                      value: @customer.billing_email.to_s
                    )
                    render RubyUI::FormFieldError.new
                  end

                  render RubyUI::FormField.new do
                    render RubyUI::FormFieldLabel.new { "Billing Phone" }
                    render RubyUI::Input.new(
                      type: :tel,
                      name: "customer[billing_phone]",
                      placeholder: "Enter billing phone",
                      value: @customer.billing_phone.to_s
                    )
                    render RubyUI::FormFieldError.new
                  end
                end
              end
            end


            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Notes" }
              render RubyUI::Textarea.new(
                name: "customer[notes]",
                placeholder: "Enter additional notes",
                rows: 4
              ) do
                @customer.notes.to_s
              end
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
