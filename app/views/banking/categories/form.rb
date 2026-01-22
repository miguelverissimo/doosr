# frozen_string_literal: true

module Views
  module Banking
    module Categories
      class Form < ::Views::Base
        DEFAULT_COLORS = %w[
          #dc2626 #ea580c #ca8a04 #65a30d #16a34a
          #0d9488 #0891b2 #2563eb #4f46e5 #7c3aed
          #c026d3 #db2777 #78716c #52525b #475569
        ].freeze

        def initialize(category:, parent_categories: [])
          @category = category
          @parent_categories = parent_categories
        end

        def view_template
          div(id: "categories_form", class: "space-y-4", data: { controller: "modal-form" }) do
            render_back_button
            render_form_header
            render_form
          end
        end

        private

        def editing?
          @category.persisted?
        end

        def render_back_button
          div(class: "mb-4") do
            form(
              action: view_context.list_banking_categories_path,
              method: "get",
              data: { turbo_stream: true },
              class: "inline"
            ) do
              button(
                type: "submit",
                class: "inline-flex items-center text-sm text-muted-foreground hover:text-foreground"
              ) do
                render ::Components::Icon::ArrowLeft.new(size: "16", class: "mr-1")
                plain "Back to categories"
              end
            end
          end
        end

        def render_form_header
          h3(class: "text-lg font-medium mb-4") do
            plain editing? ? "Edit Category" : "New Category"
          end
        end

        def render_form
          form(
            action: form_action,
            method: "post",
            data: {
              controller: "form-loading",
              form_loading_message_value: editing? ? "Updating category..." : "Creating category...",
              turbo: true
            },
            class: "space-y-4"
          ) do
            csrf_token_field
            render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch") if editing?

            div(id: "category_form_errors", class: "text-sm text-destructive")

            render_name_field
            render_parent_field if @parent_categories.any?
            render_color_field

            render_actions
          end
        end

        def form_action
          if editing?
            view_context.banking_category_path(@category)
          else
            view_context.banking_categories_path
          end
        end

        def csrf_token_field
          render RubyUI::Input.new(
            type: :hidden,
            name: "authenticity_token",
            value: view_context.form_authenticity_token
          )
        end

        def render_name_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "category_name") { "Name" }
            render RubyUI::Input.new(
              type: :text,
              id: "category_name",
              name: "category[name]",
              value: @category.name,
              required: true,
              placeholder: "e.g., Groceries"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_parent_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "category_parent_id") { "Parent Category (optional)" }
            div(class: "text-xs text-muted-foreground mb-2") do
              plain "Make this a subcategory of another category"
            end
            select(
              id: "category_parent_id",
              name: "category[parent_id]",
              class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            ) do
              option(value: "", selected: @category.parent_id.nil?) { "None (top-level category)" }
              @parent_categories.each do |parent|
                option(
                  value: parent.id,
                  selected: @category.parent_id == parent.id
                ) { parent.name }
              end
            end
            render RubyUI::FormFieldError.new
          end
        end

        def render_color_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Color" }
            div(class: "space-y-3", data: { controller: "color-input" }) do
              render_color_picker
              render_color_palette
            end
            render RubyUI::FormFieldError.new
          end
        end

        def render_color_picker
          div(class: "flex items-center gap-3") do
            div(
              id: "color_preview",
              class: "h-10 w-10 rounded-lg border border-border",
              style: "background-color: #{@category.color || DEFAULT_COLORS.first};"
            )
            render RubyUI::Input.new(
              type: :text,
              id: "category_color",
              name: "category[color]",
              value: @category.color || DEFAULT_COLORS.first,
              pattern: "^#[0-9A-Fa-f]{6}$",
              placeholder: "#22c55e",
              class: "font-mono",
              data: {
                action: "input->color-input#updatePreview"
              }
            )
          end
        end

        def render_color_palette
          div(class: "flex flex-wrap gap-2") do
            DEFAULT_COLORS.each do |color|
              button(
                type: "button",
                class: "h-8 w-8 rounded-lg border-2 transition-all hover:scale-110 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
                style: "background-color: #{color}; border-color: #{@category.color == color ? 'currentColor' : 'transparent'};",
                data: {
                  action: "click->color-input#selectColor",
                  color_input_color_param: color
                }
              )
            end
          end
        end

        def render_actions
          div(class: "flex gap-2 justify-end mt-6") do
            button(
              type: "button",
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2",
              data: {
                action: "click->modal-form#cancelDialog",
                modal_form_dialog_id_param: "categories_dialog"
              }
            ) { "Cancel" }
            Button(variant: :primary, type: "submit") do
              plain editing? ? "Save Changes" : "Create Category"
            end
          end
        end
      end
    end
  end
end
