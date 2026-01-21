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
            render_label_field
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
