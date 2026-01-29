# frozen_string_literal: true

module Views
  module Banking
    module TransferPatterns
      class Form < ::Views::Base
        def initialize(transfer_pattern:)
          @transfer_pattern = transfer_pattern
        end

        def view_template
          div(id: "transfer_patterns_content", class: "space-y-4") do
            render_back_button
            render_form_header
            render_form
          end
        end

        private

        def editing?
          @transfer_pattern.persisted?
        end

        def render_back_button
          button(
            type: "button",
            class: "inline-flex items-center text-sm text-muted-foreground hover:text-foreground mb-4",
            data: {
              controller: "turbo-fetch",
              turbo_fetch_url_value: view_context.banking_transfer_patterns_path(content_only: true),
              action: "click->turbo-fetch#load"
            }
          ) do
            render ::Components::Icon::ArrowLeft.new(size: "16", class: "mr-1")
            plain "Back to patterns"
          end
        end

        def render_form_header
          h3(class: "text-lg font-semibold mb-4") do
            plain editing? ? "Edit Transfer Pattern" : "Add Transfer Pattern"
          end
        end

        def form_action
          if editing?
            view_context.banking_transfer_pattern_path(@transfer_pattern)
          else
            view_context.banking_transfer_patterns_path
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

            div(id: "transfer_pattern_form_errors", class: "text-sm text-destructive")

            render_pattern_field
            render_label_field
            render_apply_existing_field unless editing?
            render_actions
          end
        end

        def render_pattern_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "transfer_pattern_pattern") { "Pattern" }
            p(class: "text-xs text-muted-foreground mb-2") do
              plain "Enter text that identifies internal transfers (case-insensitive). Example: TRANSFER TO SAVINGS"
            end
            render RubyUI::Input.new(
              type: :text,
              id: "transfer_pattern_pattern",
              name: "transfer_pattern[pattern]",
              value: @transfer_pattern.pattern,
              required: true,
              placeholder: "e.g., TRANSFER, TRF TO, INTERNAL"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_label_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "transfer_pattern_label") { "Label (optional)" }
            p(class: "text-xs text-muted-foreground mb-2") do
              plain "A friendly name to describe this transfer type"
            end
            render RubyUI::Input.new(
              type: :text,
              id: "transfer_pattern_label",
              name: "transfer_pattern[label]",
              value: @transfer_pattern.label,
              placeholder: "e.g., Savings Transfer, Credit Card Payment"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_apply_existing_field
          div(class: "flex items-center space-x-2") do
            input(
              type: "checkbox",
              id: "apply_to_existing",
              name: "apply_to_existing",
              value: "1",
              checked: true,
              class: "h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
            )
            label(for: "apply_to_existing", class: "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70") do
              plain "Apply to existing transactions"
            end
          end
          p(class: "text-xs text-muted-foreground mt-1") do
            plain "If checked, matching transactions will be marked as transfers immediately."
          end
        end

        def render_actions
          div(class: "flex gap-2 justify-end mt-6") do
            button(
              type: "button",
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2",
              data: {
                controller: "turbo-fetch",
                turbo_fetch_url_value: view_context.banking_transfer_patterns_path(content_only: true),
                action: "click->turbo-fetch#load"
              }
            ) do
              plain "Cancel"
            end
            Button(variant: :primary, type: "submit") do
              plain editing? ? "Update Pattern" : "Create Pattern"
            end
          end
        end
      end
    end
  end
end
