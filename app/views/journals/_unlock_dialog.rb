# frozen_string_literal: true

module Views
  module Journals
    class UnlockDialog < ::Views::Base
      def initialize(error: nil)
        @error = error
      end

      def view_template
        Dialog(open: true, id: "journal_unlock_dialog") do
          DialogContent(class: "max-w-md") do
            DialogHeader do
              DialogTitle do
                div(class: "flex items-center gap-2") do
                  render ::Components::Icon::Lock.new(size: "20")
                  plain "Unlock Journal"
                end
              end
            end

            render_unlock_form
          end
        end
      end

      private

      def render_unlock_form
        render RubyUI::Form.new(
          action: view_context.journal_unlock_path,
          method: "post",
          class: "space-y-4",
          data: {
            controller: "modal-form",
            modal_form_loading_message_value: "Unlocking...",
            turbo: true
          }
        ) do
          render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)

          if @error.present?
            div(id: "unlock_form_errors", class: "mb-4") do
              Alert(variant: :destructive) do
                AlertDescription { @error }
              end
            end
          else
            div(id: "unlock_form_errors", class: "mb-4")
          end

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Password" }
            render RubyUI::Input.new(
              type: :password,
              name: "password",
              required: true,
              placeholder: "Enter your journal password",
              autocomplete: "current-password"
            )
            render RubyUI::FormFieldError.new
          end

          p(class: "text-sm text-muted-foreground") do
            plain "Forgot password? "
            a(
              href: "#",
              class: "underline text-primary hover:text-primary/80",
              data: {
                controller: "settings-recovery",
                action: "click->modal-form#cancelDialog click->settings-recovery#openRecovery"
              }
            ) { "Use recovery phrase" }
          end

          div(class: "flex gap-2 justify-end pt-4") do
            Button(
              variant: :outline,
              type: :button,
              data: { action: "click->modal-form#cancelDialog" }
            ) { "Cancel" }
            Button(variant: :primary, type: :submit) { "Unlock" }
          end
        end
      end
    end
  end
end
