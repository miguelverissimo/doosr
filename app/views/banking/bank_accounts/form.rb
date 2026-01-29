# frozen_string_literal: true

module Views
  module Banking
    module BankAccounts
      class Form < ::Views::Base
        ACCOUNT_TYPE_OPTIONS = [
          { value: "checking", label: "Checking" },
          { value: "savings", label: "Savings" },
          { value: "credit_card", label: "Credit Card" },
          { value: "investment", label: "Investment" },
          { value: "other", label: "Other" }
        ].freeze

        def initialize(bank_account:)
          @bank_account = bank_account
        end

        def view_template
          div(id: "bank_accounts_content", class: "space-y-4") do
            render_back_button
            render_form_header
            render_form
          end
        end

        private

        def editing?
          @bank_account.persisted?
        end

        def render_back_button
          button(
            type: "button",
            class: "inline-flex items-center text-sm text-muted-foreground hover:text-foreground mb-4",
            data: {
              controller: "turbo-fetch",
              turbo_fetch_url_value: view_context.banking_bank_accounts_path(content_only: true),
              action: "click->turbo-fetch#load"
            }
          ) do
            render ::Components::Icon::ArrowLeft.new(size: "16", class: "mr-1")
            plain "Back to accounts"
          end
        end

        def render_form_header
          h3(class: "text-lg font-semibold mb-4") do
            plain editing? ? "Edit Account" : "Add Account"
          end
        end

        def form_action
          if editing?
            view_context.banking_bank_account_path(@bank_account)
          else
            view_context.banking_bank_accounts_path
          end
        end

        def render_form
          form(
            action: form_action,
            method: "post",
            data: { turbo: true, turbo_stream: true },
            class: "space-y-4"
          ) do
            render RubyUI::Input.new(
              type: :hidden,
              name: "authenticity_token",
              value: view_context.form_authenticity_token
            )
            render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch") if editing?

            div(id: "bank_account_form_errors", class: "text-sm text-destructive")

            render_name_field
            render_account_type_field
            render_display_options
            render_active_field if editing?
            render_actions
          end
        end

        def render_name_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "bank_account_name") { "Account Name" }
            p(class: "text-xs text-muted-foreground mb-2") do
              plain "Enter a name to identify this account (e.g., 'Main Checking', 'Savings')"
            end
            render RubyUI::Input.new(
              type: :text,
              id: "bank_account_name",
              name: "bank_account[name]",
              value: @bank_account.name,
              required: true,
              placeholder: "e.g., Main Checking"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_account_type_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "bank_account_account_type") { "Account Type" }
            select(
              id: "bank_account_account_type",
              name: "bank_account[account_type]",
              class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            ) do
              ACCOUNT_TYPE_OPTIONS.each do |option|
                option(
                  value: option[:value],
                  selected: @bank_account.account_type == option[:value]
                ) { option[:label] }
              end
            end
            render RubyUI::FormFieldError.new
          end
        end

        def render_display_options
          div(class: "space-y-4 p-4 rounded-md border border-border") do
            h4(class: "text-sm font-medium mb-3") { "Display Options" }

            div(class: "grid grid-cols-3 gap-4") do
              render_letter_field
              render_bg_color_field
              render_fg_color_field
            end

            render_badge_preview
          end
        end

        def render_letter_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "bank_account_letter") { "Letter" }
            render RubyUI::Input.new(
              type: :text,
              id: "bank_account_letter",
              name: "bank_account[letter]",
              value: @bank_account.letter.presence || @bank_account.name&.first&.upcase,
              maxlength: 2,
              placeholder: "M",
              data: { action: "input->bank-account-preview#update" }
            )
          end
        end

        def render_bg_color_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "bank_account_bg_color") { "Background" }
            input(
              type: "color",
              id: "bank_account_bg_color",
              name: "bank_account[bg_color]",
              value: @bank_account.bg_color || "#3B82F6",
              class: "h-9 w-full rounded-md border border-border cursor-pointer",
              data: { action: "input->bank-account-preview#update" }
            )
          end
        end

        def render_fg_color_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "bank_account_fg_color") { "Text Color" }
            input(
              type: "color",
              id: "bank_account_fg_color",
              name: "bank_account[fg_color]",
              value: @bank_account.fg_color || "#FFFFFF",
              class: "h-9 w-full rounded-md border border-border cursor-pointer",
              data: { action: "input->bank-account-preview#update" }
            )
          end
        end

        def render_badge_preview
          div(
            class: "flex items-center gap-3 mt-4 pt-4 border-t border-border",
            data: { controller: "bank-account-preview" }
          ) do
            span(class: "text-sm text-muted-foreground") { "Preview:" }
            div(
              id: "bank_account_badge_preview",
              class: "inline-flex items-center justify-center w-7 h-7 rounded-full text-xs font-bold",
              style: "background-color: #{@bank_account.bg_color || '#3B82F6'}; color: #{@bank_account.fg_color || '#FFFFFF'};",
              data: { bank_account_preview_target: "badge" }
            ) do
              plain @bank_account.letter.presence || @bank_account.name&.first&.upcase || "M"
            end
          end
        end

        def render_active_field
          div(class: "flex items-center space-x-2") do
            input(
              type: "checkbox",
              id: "bank_account_active",
              name: "bank_account[active]",
              value: "1",
              checked: @bank_account.active?,
              class: "h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
            )
            label(for: "bank_account_active", class: "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70") do
              plain "Active"
            end
          end
          p(class: "text-xs text-muted-foreground mt-1") do
            plain "Inactive accounts won't appear in the import dialog."
          end
        end

        def render_actions
          div(class: "flex gap-2 justify-end mt-6") do
            button(
              type: "button",
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2",
              data: {
                controller: "turbo-fetch",
                turbo_fetch_url_value: view_context.banking_bank_accounts_path(content_only: true),
                action: "click->turbo-fetch#load"
              }
            ) do
              plain "Cancel"
            end
            Button(variant: :primary, type: "submit") do
              plain editing? ? "Update Account" : "Create Account"
            end
          end
        end
      end
    end
  end
end
