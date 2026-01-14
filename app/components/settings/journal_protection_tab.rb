# frozen_string_literal: true

module Components
  module Settings
    class JournalProtectionTab < ::Components::Base
      DIALOG_ID = "journal_protection_tab"

      def initialize(user:, active_form: nil, errors: nil, seed_phrase: nil)
        @user = user
        @active_form = active_form
        @errors = errors
        @seed_phrase = seed_phrase
      end

      def view_template
        div(
          id: DIALOG_ID,
          class: "space-y-4",
          data: { controller: "settings-journal-protection" }
        ) do
          div(class: "flex items-center gap-4") do
            render_status_badge
            render_description
          end

          if @user.journal_protection_enabled?
            render_protected_state
          else
            render_unprotected_state
          end
        end
      end

      private

      def render_status_badge
        div(class: "flex items-center gap-2") do
          if @user.journal_protection_enabled?
            BadgeWithIcon(icon: :lock, variant: :lime) do
              plain "Protected"
            end
          else
            BadgeWithIcon(icon: :lock_open, variant: :orange) do
              plain "Not Protected"
            end
          end
        end
      end

      def render_description
        p(class: "text-sm text-muted-foreground") do
          if @user.journal_protection_enabled?
            plain "Your journal entries are encrypted and protected with a password."
          else
            plain "Your journal entries are not currently protected."
          end
        end
      end

      def render_protected_state
        div(class: "pt-2 space-y-4") do
          if @active_form == "change_password"
            render_change_password_form
          elsif @active_form == "recover"
            render_recovery_form
          elsif @active_form == "disable"
            render_disable_form
          elsif @active_form == "session_timeout"
            render_session_timeout_form
          else
            render_protected_actions
            render_session_timeout_display
          end
        end
      end

      def render_unprotected_state
        div(class: "pt-2") do
          if @active_form == "enable" && @seed_phrase
            render_seed_phrase_step
          elsif @active_form == "enable"
            render_enable_form
          else
            render_enable_button
          end
        end
      end

      def render_protected_actions
        div(class: "flex flex-wrap gap-2") do
          render RubyUI::Form.new(
            action: view_context.journal_protection_settings_path,
            method: "get",
            data: { turbo_stream: true }
          ) do
            render RubyUI::Input.new(type: :hidden, name: "tab_form", value: "change_password")
            Button(variant: :tinted, tint: :sky, type: :submit, size: :sm) do
              render ::Components::Icon::Key.new(size: "14", class: "mr-1")
              plain "Change Password"
            end
          end

          render RubyUI::Form.new(
            action: view_context.journal_protection_settings_path,
            method: "get",
            data: { turbo_stream: true }
          ) do
            render RubyUI::Input.new(type: :hidden, name: "tab_form", value: "recover")
            Button(variant: :tinted, tint: :fuchsia, type: :submit, size: :sm) do
              render ::Components::Icon::Refresh.new(size: "14", class: "mr-1")
              plain "Recover via Seed Phrase"
            end
          end

          render RubyUI::Form.new(
            action: view_context.journal_protection_settings_path,
            method: "get",
            data: { turbo_stream: true }
          ) do
            render RubyUI::Input.new(type: :hidden, name: "tab_form", value: "disable")
            Button(variant: :destructive, type: :submit, size: :sm) do
              render ::Components::Icon::LockOpen.new(size: "14", class: "mr-1")
              plain "Disable Protection"
            end
          end
        end
      end

      def render_enable_button
        render RubyUI::Form.new(
          action: view_context.journal_protection_settings_path,
          method: "get",
          data: { turbo_stream: true }
        ) do
          render RubyUI::Input.new(type: :hidden, name: "tab_form", value: "enable")
          Button(variant: :primary, type: :submit) do
            render ::Components::Icon::Lock.new(size: "16", class: "mr-2")
            plain "Enable Protection"
          end
        end
      end

      def render_enable_form
        div(class: "border rounded-lg p-4 bg-muted/50") do
          h3(class: "text-sm font-semibold mb-3") { "Enable Journal Protection" }

          render RubyUI::Form.new(
            action: view_context.journal_protection_settings_path,
            method: "post",
            class: "space-y-4",
            id: "enable_protection_form",
            data: {
              controller: "modal-form",
              modal_form_loading_message_value: "Setting up protection...",
              turbo: true
            }
          ) do
            render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            render RubyUI::Input.new(type: :hidden, name: "step", value: "generate_seed")
            render RubyUI::Input.new(type: :hidden, name: "from_tab", value: "true")

            render_errors if @errors.present?

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Password" }
              render RubyUI::Input.new(
                type: :password,
                name: "password",
                required: true,
                placeholder: "Enter a strong password (min 8 characters)",
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

            render_form_actions("Enable Protection", cancel_form: "enable")
          end
        end
      end

      def render_seed_phrase_step
        div(class: "border rounded-lg p-4 bg-muted/50") do
          h3(class: "text-sm font-semibold mb-3") { "Save Your Recovery Phrase" }

          render RubyUI::Form.new(
            action: view_context.journal_protection_settings_path,
            method: "post",
            class: "space-y-4",
            id: "confirm_seed_form",
            data: {
              controller: "modal-form seed-phrase-confirm",
              modal_form_loading_message_value: "Enabling protection...",
              turbo: true
            }
          ) do
            render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            render RubyUI::Input.new(type: :hidden, name: "step", value: "confirm_seed")
            render RubyUI::Input.new(type: :hidden, name: "seed_phrase", value: @seed_phrase)
            render RubyUI::Input.new(type: :hidden, name: "from_tab", value: "true")

            Alert(variant: :warning, class: "mb-4") do
              AlertTitle { "Important: Save This Recovery Phrase!" }
              AlertDescription do
                plain "If you forget your password, this is the ONLY way to recover your journal. "
                plain "Write it down and keep it safe. You will NOT see it again."
              end
            end

            div(class: "p-4 bg-background rounded-lg font-mono text-sm break-words border") do
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
              render_cancel_button("enable")
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

      def render_change_password_form
        div(class: "border rounded-lg p-4 bg-muted/50") do
          h3(class: "text-sm font-semibold mb-3") { "Change Journal Password" }

          render RubyUI::Form.new(
            action: view_context.journal_protection_settings_path,
            method: "patch",
            class: "space-y-4",
            id: "change_password_form",
            data: {
              controller: "modal-form",
              modal_form_loading_message_value: "Changing password...",
              turbo: true
            }
          ) do
            render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            render RubyUI::Input.new(type: :hidden, name: "from_tab", value: "true")

            render_errors if @errors.present?

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

            p(class: "text-xs text-muted-foreground") do
              plain "Your existing journal entries will be re-encrypted with the new password in the background."
            end

            render_form_actions("Change Password", cancel_form: "change_password")
          end
        end
      end

      def render_recovery_form
        div(class: "border rounded-lg p-4 bg-muted/50") do
          h3(class: "text-sm font-semibold mb-3") { "Recover via Seed Phrase" }

          render RubyUI::Form.new(
            action: view_context.journal_recovery_path,
            method: "post",
            class: "space-y-4",
            id: "recovery_form",
            data: {
              controller: "modal-form",
              modal_form_loading_message_value: "Resetting password...",
              turbo: true
            }
          ) do
            render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            render RubyUI::Input.new(type: :hidden, name: "from_tab", value: "true")

            render_errors if @errors.present?

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Recovery Phrase" }
              render RubyUI::Textarea.new(
                name: "seed_phrase",
                required: true,
                placeholder: "Enter your 12-word recovery phrase",
                rows: 2
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

            render_form_actions("Reset Password", cancel_form: "recover")
          end
        end
      end

      def render_disable_form
        div(class: "border rounded-lg p-4 bg-destructive/10") do
          h3(class: "text-sm font-semibold mb-3 text-destructive") { "Disable Journal Protection" }

          Alert(variant: :warning, class: "mb-4") do
            AlertDescription do
              plain "This will decrypt all your journal entries. Your entries will be stored unencrypted "
              plain "and anyone with access to the database could read them."
            end
          end

          render RubyUI::Form.new(
            action: view_context.journal_protection_settings_path,
            method: "delete",
            class: "space-y-4",
            id: "disable_protection_form",
            data: {
              controller: "modal-form",
              modal_form_loading_message_value: "Disabling protection...",
              turbo: true
            }
          ) do
            render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            render RubyUI::Input.new(type: :hidden, name: "from_tab", value: "true")

            render_errors if @errors.present?

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

            div(class: "flex gap-2 justify-end pt-4") do
              render_cancel_button("disable")
              Button(variant: :destructive, type: :submit) { "Disable Protection" }
            end
          end
        end
      end

      def render_errors
        div(class: "mb-4") do
          Alert(variant: :destructive) do
            AlertDescription { @errors.join(", ") }
          end
        end
      end

      def render_form_actions(submit_text, cancel_form:)
        div(class: "flex gap-2 justify-end pt-4") do
          render_cancel_button(cancel_form)
          Button(variant: :primary, type: :submit) { submit_text }
        end
      end

      def render_session_timeout_display
        div(class: "border rounded-lg p-4 bg-muted/50 mt-4") do
          div(class: "flex items-center justify-between") do
            div do
              h4(class: "text-sm font-semibold mb-1") { "Session Timeout" }
              p(class: "text-sm text-muted-foreground") do
                plain "Currently set to #{@user.journal_session_timeout_minutes} minutes of inactivity"
              end
            end

            render RubyUI::Form.new(
              action: view_context.journal_protection_settings_path,
              method: "get",
              data: { turbo_stream: true }
            ) do
              render RubyUI::Input.new(type: :hidden, name: "tab_form", value: "session_timeout")
              Button(variant: :outline, type: :submit, size: :sm) { "Change Timeout" }
            end
          end
        end
      end

      def render_session_timeout_form
        div(class: "border rounded-lg p-4 bg-muted/50") do
          h3(class: "text-sm font-semibold mb-3") { "Change Session Timeout" }

          render RubyUI::Form.new(
            action: view_context.update_session_timeout_journal_protection_settings_path,
            method: "patch",
            class: "space-y-4",
            id: "session_timeout_form",
            data: {
              controller: "modal-form",
              modal_form_loading_message_value: "Updating timeout...",
              turbo: true
            }
          ) do
            render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
            render RubyUI::Input.new(type: :hidden, name: "from_tab", value: "true")

            render_errors if @errors.present?

            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new { "Session Timeout (minutes)" }
              render RubyUI::Input.new(
                type: :number,
                name: "session_timeout_minutes",
                value: @user.journal_session_timeout_minutes,
                required: true,
                min: 5,
                max: 1440,
                placeholder: "30"
              )
              p(class: "text-xs text-muted-foreground mt-1") do
                plain "After this many minutes of inactivity, you'll need to unlock your journal again. Minimum: 5 minutes, Maximum: 1440 minutes (24 hours)"
              end
              render RubyUI::FormFieldError.new
            end

            render_form_actions("Update Timeout", cancel_form: "session_timeout")
          end
        end
      end

      def render_cancel_button(form_name)
        Button(
          variant: :outline,
          type: "button",
          data: {
            action: "click->settings-journal-protection#cancelForm"
          }
        ) { "Cancel" }
      end
    end
  end
end
