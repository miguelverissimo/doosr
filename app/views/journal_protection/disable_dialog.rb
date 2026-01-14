# frozen_string_literal: true

module Views
  module JournalProtection
    class DisableDialog < ::Views::Base
      def initialize(errors: nil)
        @errors = errors
      end

      def view_template
        div(id: "disable_protection_dialog") do
          render RubyUI::AlertDialog.new(open: true) do
            render RubyUI::AlertDialogContent.new(class: "max-w-md") do
              render RubyUI::AlertDialogHeader.new do
                render RubyUI::AlertDialogTitle.new { "Disable Journal Protection?" }
                render RubyUI::AlertDialogDescription.new do
                  plain "This will decrypt all your journal entries. Your entries will be stored unencrypted "
                  plain "and anyone with access to the database could read them."
                end
              end

              render_password_form
            end
          end
        end
      end

      private

      def render_password_form
        render RubyUI::Form.new(
          action: view_context.journal_protection_settings_path,
          method: "delete",
          class: "mt-4 space-y-4",
          data: {
            controller: "modal-form",
            modal_form_loading_message_value: "Disabling protection...",
            turbo: true,
            action: "submit@document->ruby-ui--alert-dialog#dismiss"
          }
        ) do
          render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)

          if @errors.present?
            div(id: "disable_form_errors", class: "mb-4") do
              Alert(variant: :destructive) do
                AlertDescription { @errors.join(", ") }
              end
            end
          else
            div(id: "disable_form_errors", class: "mb-4")
          end

          Alert(variant: :warning, class: "mb-4") do
            AlertDescription do
              plain "All encrypted journal entries will be decrypted in the background. "
              plain "This may take a moment if you have many entries."
            end
          end

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Enter your password to confirm" }
            render RubyUI::Input.new(
              type: :password,
              name: "current_password",
              required: true,
              placeholder: "Enter your current password",
              autocomplete: "current-password"
            )
            render RubyUI::FormFieldError.new
          end

          render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
            render RubyUI::AlertDialogCancel.new(
              data: { action: "click->modal-form#cancelDialog" }
            ) { "Cancel" }
            render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Disable Protection" }
          end
        end
      end
    end
  end
end
