module Components
  module Accounting
    module Settings
      module BankInfos
        class Form < Components::Base
          def initialize(bank_info: nil)
            @bank_info = bank_info || ::Accounting::BankInfo.new
            @is_new_record = @bank_info.new_record?
            @action = @is_new_record ? "Create" : "Update"
            super(**attrs)
          end

          def view_template
            form_url = if @is_new_record
              view_context.settings_bank_infos_path
            else
              view_context.settings_bank_info_path(@bank_info)
            end

            render RubyUI::Form.new(
              action: form_url,
              method: "post",
              class: "space-y-6",
              data: {
                controller: "bank-info-form",
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
                  name: "bank_info[name]",
                  placeholder: "Enter name",
                  value: @bank_info.name.to_s,
                  required: true
                )
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Account Number" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "bank_info[account_number]",
                  placeholder: "Enter account number",
                  value: @bank_info.account_number.to_s,
                  data: {
                    bank_info_form_target: "accountNumber",
                    action: "input->bank-info-form#onInput"
                  }
                )
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Routing Number" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "bank_info[routing_number]",
                  placeholder: "Enter routing number",
                  value: @bank_info.routing_number.to_s,
                  data: {
                    bank_info_form_target: "routingNumber",
                    action: "input->bank-info-form#onInput"
                  }
                )
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "IBAN" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "bank_info[iban]",
                  placeholder: "Enter IBAN",
                  value: @bank_info.iban.to_s,
                  data: {
                    bank_info_form_target: "iban",
                    action: "input->bank-info-form#onInput"
                  }
                )
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "SWIFT/BIC" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "bank_info[swift_bic]",
                  placeholder: "Enter SWIFT/BIC",
                  value: @bank_info.swift_bic.to_s,
                  data: {
                    bank_info_form_target: "swiftBic",
                    action: "input->bank-info-form#onInput"
                  }
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
