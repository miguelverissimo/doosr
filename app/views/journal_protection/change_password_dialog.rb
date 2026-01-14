# frozen_string_literal: true

module Views
  module JournalProtection
    class ChangePasswordDialog < ::Views::Base
      def initialize(errors: nil)
        @errors = errors
      end

      def view_template
        Dialog(open: true, id: "change_password_dialog") do
          DialogContent(class: "max-w-md") do
            DialogHeader do
              DialogTitle { "Change Journal Password" }
            end

            render_password_form
          end
        end
      end

      private

      def render_password_form
        render RubyUI::Form.new(
          action: view_context.journal_protection_settings_path,
          method: "patch",
          class: "space-y-4",
          data: {
            controller: "modal-form",
            modal_form_loading_message_value: "Changing password...",
            turbo: true
          }
        ) do
          render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)

          if @errors.present?
            div(id: "change_password_errors", class: "mb-4") do
              Alert(variant: :destructive) do
                AlertDescription { @errors.join(", ") }
              end
            end
          else
            div(id: "change_password_errors", class: "mb-4")
          end

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Current Password" }
            render RubyUI::Input.new(
              type: :password,
              name: "current_password",
              required: true,
              placeholder: "Enter your current password",
              autocomplete: "current-password"
            )
            render RubyUI::FormFieldError.new
          end

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "New Password" }
            render RubyUI::Input.new(
              type: :password,
              name: "new_password",
              required: true,
              placeholder: "Enter a new password",
              autocomplete: "new-password"
            )
            render RubyUI::FormFieldError.new
          end

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Confirm New Password" }
            render RubyUI::Input.new(
              type: :password,
              name: "new_password_confirmation",
              required: true,
              placeholder: "Confirm your new password",
              autocomplete: "new-password"
            )
            render RubyUI::FormFieldError.new
          end

          p(class: "text-sm text-muted-foreground") do
            plain "Your existing journal entries will be re-encrypted with the new password in the background."
          end

          div(class: "flex gap-2 justify-end pt-4") do
            Button(
              variant: :outline,
              type: :button,
              data: { action: "click->modal-form#cancelDialog" }
            ) { "Cancel" }
            Button(variant: :primary, type: :submit) { "Change Password" }
          end
        end
      end
    end
  end
end
