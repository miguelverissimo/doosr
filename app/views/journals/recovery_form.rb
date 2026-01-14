# frozen_string_literal: true

module Views
  module Journals
    class RecoveryForm < ::Views::Base
      def initialize(errors: nil, seed_phrase: nil)
        @errors = errors
        @seed_phrase = seed_phrase
      end

      def view_template
        div(id: "recovery_form_container", class: "flex h-full flex-col p-4") do
          div(class: "max-w-md mx-auto rounded-lg border p-4 md:p-6 space-y-4 bg-background text-foreground") do
            div(class: "flex flex-col gap-2 mb-4") do
              div(class: "flex items-center gap-2") do
                render ::Components::Icon::Key.new(size: "24")
                h1(class: "text-xl font-bold") { "Recover Journal Access" }
              end
              p(class: "text-muted-foreground text-sm") do
                plain "Enter your 12-word recovery phrase to reset your password"
              end
            end

            render_recovery_form
          end

          render_back_link
        end
      end

      private

      def render_recovery_form
        render RubyUI::Form.new(
          action: view_context.journal_recovery_path,
          method: "post",
          class: "space-y-4",
          data: {
            controller: "modal-form",
            modal_form_loading_message_value: "Resetting password...",
            turbo: true
          }
        ) do
          render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)

          render_errors if @errors.present?

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Recovery Phrase" }
            render RubyUI::Textarea.new(
              name: "seed_phrase",
              required: true,
              placeholder: "Enter your 12-word recovery phrase",
              rows: 3,
              value: @seed_phrase
            )
            p(class: "text-xs text-muted-foreground mt-1") do
              plain "Enter all 12 words separated by spaces"
            end
            render RubyUI::FormFieldError.new
          end

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "New Password" }
            render RubyUI::Input.new(
              type: :password,
              name: "password",
              required: true,
              placeholder: "Enter new password",
              autocomplete: "new-password"
            )
            render RubyUI::FormFieldError.new
          end

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Confirm New Password" }
            render RubyUI::Input.new(
              type: :password,
              name: "password_confirmation",
              required: true,
              placeholder: "Confirm new password",
              autocomplete: "new-password"
            )
            render RubyUI::FormFieldError.new
          end

          div(class: "flex gap-2 justify-end pt-4") do
            render ::Components::ColoredLink.new(
              href: view_context.journals_path,
              variant: :outline
            ) { "Cancel" }
            Button(variant: :primary, type: :submit) { "Reset Password" }
          end
        end
      end

      def render_errors
        div(class: "mb-4") do
          Alert(variant: :destructive) do
            AlertDescription do
              ul(class: "list-disc pl-4") do
                @errors.each do |error|
                  li { error }
                end
              end
            end
          end
        end
      end

      def render_back_link
        div(class: "max-w-md mx-auto mt-4") do
          render ::Components::ColoredLink.new(
            href: view_context.journals_path,
            variant: :ghost,
            size: :sm
          ) do
            render ::Components::Icon::ArrowLeft.new(size: "16", class: "mr-1")
            plain "Back to Journals"
          end
        end
      end
    end
  end
end
