module Components
  module Accounting
    module Receipts
      class FormWithCalculator < Components::Base
        def initialize(receipt: nil)
          @receipt = nil # receipt || ::Accounting::Receipt.new
          @is_new_record = true # @receipt.new_record?
          @action = @is_new_record ? "Create" : "Update"
          super(**attrs)
        end

        def view_template
          form_url = if @is_new_record
            view_context.receipts_path
          else
            view_context.receipt_path(@receipt)
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

            # Form fields with calculator will be added here

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

