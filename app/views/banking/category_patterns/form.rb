# frozen_string_literal: true

module Views
  module Banking
    module CategoryPatterns
      class Form < ::Views::Base
        def initialize(category_pattern:, categories:)
          @category_pattern = category_pattern
          @categories = categories
        end

        def view_template
          div(id: "category_patterns_content", class: "space-y-4") do
            render_back_button
            render_form_header
            render_form
          end
        end

        private

        def editing?
          @category_pattern.persisted?
        end

        def render_back_button
          button(
            type: "button",
            class: "inline-flex items-center text-sm text-muted-foreground hover:text-foreground mb-4",
            data: {
              controller: "turbo-fetch",
              turbo_fetch_url_value: view_context.banking_category_patterns_path(content_only: true),
              action: "click->turbo-fetch#load"
            }
          ) do
            render ::Components::Icon::ArrowLeft.new(size: "16", class: "mr-1")
            plain "Back to patterns"
          end
        end

        def render_form_header
          h3(class: "text-lg font-semibold mb-4") do
            plain editing? ? "Edit Pattern" : "Add Pattern"
          end
        end

        def form_action
          if editing?
            view_context.banking_category_pattern_path(@category_pattern)
          else
            view_context.banking_category_patterns_path
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
            render RubyUI::Input.new(type: :hidden, name: "from_list", value: "1")

            div(id: "category_pattern_form_errors", class: "text-sm text-destructive")

            render_pattern_field
            render_label_field
            render_category_field
            render_apply_existing_field unless editing?
            render_actions
          end
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

        def render_label_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "category_pattern_label") { "Label (optional)" }
            p(class: "text-xs text-muted-foreground mb-2") do
              plain "A friendly name to display instead of the raw description"
            end
            render RubyUI::Input.new(
              type: :text,
              id: "category_pattern_label",
              name: "category_pattern[label]",
              value: @category_pattern.label,
              placeholder: "e.g., Amazon, Uber Eats, Coffee"
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
            button(
              type: "button",
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2",
              data: {
                controller: "turbo-fetch",
                turbo_fetch_url_value: view_context.banking_category_patterns_path(content_only: true),
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
