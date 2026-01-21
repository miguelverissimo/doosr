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
          selected_category = find_selected_category

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Category" }
            Combobox do
              ComboboxTrigger(placeholder: "Select a category") do
                if selected_category
                  render_category_badge(selected_category)
                end
              end

              ComboboxPopover do
                ComboboxSearchInput(placeholder: "Search categories...")

                ComboboxList do
                  ComboboxEmptyState { "No categories found" }

                  @categories.each do |category|
                    if category.subcategories.any?
                      ComboboxListGroup(label: category.name) do
                        render_category_combobox_item(category, selected_category)
                        category.subcategories.order(:name).each do |sub|
                          render_category_combobox_item(sub, selected_category)
                        end
                      end
                    else
                      render_category_combobox_item(category, selected_category)
                    end
                  end
                end
              end
            end
            render RubyUI::FormFieldError.new
          end
        end

        def find_selected_category
          return nil unless @category_pattern.category_id

          @categories.each do |cat|
            return cat if cat.id == @category_pattern.category_id
            cat.subcategories.each do |sub|
              return sub if sub.id == @category_pattern.category_id
            end
          end
          nil
        end

        def render_category_combobox_item(category, selected_category)
          is_selected = selected_category&.id == category.id

          ComboboxItem do
            ComboboxRadio(
              name: "category_pattern[category_id]",
              value: category.id.to_s,
              checked: is_selected
            )
            render_category_badge(category)
          end
        end

        def render_category_badge(category)
          span(
            class: "inline-flex items-center gap-2"
          ) do
            span(
              class: "h-3 w-3 rounded-full",
              style: "background-color: #{category.effective_color}"
            )
            span { category.subcategory? ? "#{category.name}" : category.name }
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
