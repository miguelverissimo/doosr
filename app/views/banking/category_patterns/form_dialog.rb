# frozen_string_literal: true

module Views
  module Banking
    module CategoryPatterns
      class FormDialog < ::Views::Base
        def initialize(category_pattern:, categories:, transaction: nil, filter_params: {})
          @category_pattern = category_pattern
          @categories = categories
          @transaction = transaction
          @filter_params = filter_params
        end

        def view_template
          div(id: "category_pattern_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { dialog_title }
                  render RubyUI::DialogDescription.new { dialog_description }
                end

                render RubyUI::DialogMiddle.new do
                  render_form
                end
              end
            end
          end
        end

        private

        def editing?
          @category_pattern.persisted?
        end

        def dialog_title
          editing? ? "Edit Pattern" : "Create Auto-Categorization Pattern"
        end

        def dialog_description
          editing? ? "Update the pattern and category assignment" : "Create a pattern to automatically categorize matching transactions"
        end

        def form_action
          if editing?
            view_context.banking_category_pattern_path(@category_pattern)
          else
            view_context.banking_category_patterns_path
          end
        end

        def loading_message
          editing? ? "Updating pattern..." : "Creating pattern..."
        end

        def success_message
          editing? ? "Pattern updated successfully" : "Pattern created successfully"
        end

        def submit_button_text
          editing? ? "Update Pattern" : "Create Pattern"
        end

        def render_form
          form(
            action: form_action,
            method: "post",
            data: {
              controller: "modal-form",
              modal_form_loading_message_value: loading_message,
              modal_form_success_message_value: success_message,
              turbo: true
            },
            class: "space-y-4"
          ) do
            csrf_token_field
            render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch") if editing?
            render RubyUI::Input.new(type: :hidden, name: "transaction_id", value: @transaction.id) if @transaction
            render_filter_params_fields

            div(id: "category_pattern_form_errors", class: "text-sm text-destructive")

            render_pattern_field
            render_category_field
            render_apply_existing_field unless editing?

            render_actions
          end
        end

        def csrf_token_field
          render RubyUI::Input.new(
            type: :hidden,
            name: "authenticity_token",
            value: view_context.form_authenticity_token
          )
        end

        def render_pattern_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "category_pattern_pattern") { "Pattern" }
            p(class: "text-xs text-muted-foreground mb-2") do
              plain "Enter a text pattern that will match transaction descriptions (case-insensitive)"
            end
            render RubyUI::Input.new(
              type: :text,
              id: "category_pattern_pattern",
              name: "category_pattern[pattern]",
              value: @category_pattern.pattern,
              required: true,
              placeholder: "e.g., AMAZON, UBER, STARBUCKS"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_category_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "category_pattern_category_id") { "Category" }
            select(
              id: "category_pattern_category_id",
              name: "category_pattern[category_id]",
              class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
              required: true
            ) do
              option(value: "") { "Select a category" }
              @categories.each do |category|
                option(
                  value: category.id,
                  selected: @category_pattern.category_id == category.id
                ) { category.name }
              end
            end
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
              plain "Apply to existing uncategorized transactions"
            end
          end
          p(class: "text-xs text-muted-foreground mt-1") do
            plain "If checked, this pattern will be applied to all existing transactions that match and don't have a category."
          end
        end

        def render_actions
          div(class: "flex gap-2 justify-end mt-6") do
            Button(variant: :outline, type: "button", data: { action: "click->modal-form#cancelDialog" }) { "Cancel" }
            Button(variant: :primary, type: "submit") { submit_button_text }
          end
        end

        def render_filter_params_fields
          @filter_params.each do |key, value|
            render RubyUI::Input.new(type: :hidden, name: "filter[#{key}]", value: value) if value.present?
          end
        end
      end
    end
  end
end
