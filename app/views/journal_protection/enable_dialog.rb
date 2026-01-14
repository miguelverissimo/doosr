# frozen_string_literal: true

module Views
  module JournalProtection
    class EnableDialog < ::Views::Base
      def initialize(seed_phrase: nil, errors: nil)
        @seed_phrase = seed_phrase
        @errors = errors
      end

      def view_template
        Dialog(open: true, id: "enable_protection_dialog") do
          DialogContent(class: "max-w-md") do
            DialogHeader do
              DialogTitle { @seed_phrase ? "Save Your Recovery Phrase" : "Enable Journal Protection" }
            end

            if @seed_phrase
              render_seed_phrase_step
            else
              render_password_step
            end
          end
        end
      end

      private

      def render_password_step
        render RubyUI::Form.new(
          action: view_context.journal_protection_settings_path,
          method: "post",
          class: "space-y-4",
          data: {
            controller: "modal-form",
            modal_form_loading_message_value: "Setting up protection...",
            turbo: true
          }
        ) do
          render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
          render RubyUI::Input.new(type: :hidden, name: "step", value: "generate_seed")

          if @errors.present?
            div(id: "enable_form_errors", class: "mb-4") do
              Alert(variant: :destructive) do
                AlertDescription { @errors.join(", ") }
              end
            end
          else
            div(id: "enable_form_errors", class: "mb-4")
          end

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Password" }
            render RubyUI::Input.new(
              type: :password,
              name: "password",
              required: true,
              placeholder: "Enter a strong password",
              autocomplete: "new-password"
            )
            render RubyUI::FormFieldError.new
          end

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Confirm Password" }
            render RubyUI::Input.new(
              type: :password,
              name: "password_confirmation",
              required: true,
              placeholder: "Confirm your password",
              autocomplete: "new-password"
            )
            render RubyUI::FormFieldError.new
          end

          p(class: "text-sm text-muted-foreground") do
            plain "This password will be used to encrypt your journal entries. "
            plain "Make sure to remember it!"
          end

          div(class: "flex gap-2 justify-end pt-4") do
            Button(
              variant: :outline,
              type: :button,
              data: { action: "click->modal-form#cancelDialog" }
            ) { "Cancel" }
            Button(variant: :primary, type: :submit) { "Continue" }
          end
        end
      end

      def render_seed_phrase_step
        render RubyUI::Form.new(
          action: view_context.journal_protection_settings_path,
          method: "post",
          class: "space-y-4",
          data: {
            controller: "modal-form seed-phrase-confirm",
            modal_form_loading_message_value: "Enabling protection...",
            turbo: true
          }
        ) do
          render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
          render RubyUI::Input.new(type: :hidden, name: "step", value: "confirm_seed")
          render RubyUI::Input.new(type: :hidden, name: "seed_phrase", value: @seed_phrase)

          Alert(variant: :warning, class: "mb-4") do
            AlertTitle { "Important: Save This Recovery Phrase!" }
            AlertDescription do
              plain "If you forget your password, this is the ONLY way to recover your journal. "
              plain "Write it down and keep it safe. You will NOT see it again."
            end
          end

          div(class: "p-4 bg-muted rounded-lg font-mono text-sm break-words") do
            @seed_phrase
          end

          div(class: "mt-4") do
            render RubyUI::Input.new(type: :hidden, name: "seed_saved", value: "0")
            label(class: "flex items-center gap-2") do
              render RubyUI::Checkbox.new(
                name: "seed_saved",
                value: "1",
                data: {
                  seed_phrase_confirm_target: "checkbox",
                  action: "change->seed-phrase-confirm#toggleSubmit"
                }
              )
              span(class: "text-sm font-medium") { "I have saved my recovery phrase in a safe place" }
            end
          end

          div(class: "flex gap-2 justify-end pt-4") do
            Button(
              variant: :outline,
              type: :button,
              data: { action: "click->modal-form#cancelDialog" }
            ) { "Cancel" }
            Button(
              variant: :primary,
              type: :submit,
              disabled: true,
              data: { seed_phrase_confirm_target: "submitButton" }
            ) { "Enable Protection" }
          end
        end
      end
    end
  end
end
