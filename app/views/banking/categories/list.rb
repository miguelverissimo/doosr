# frozen_string_literal: true

module Views
  module Banking
    module Categories
      class List < ::Views::Base
        include RubyUI

        def initialize(categories:)
          @categories = categories
        end

        def view_template
          div(id: "categories_list", class: "space-y-4") do
            render_add_button
            render_categories_list
          end
        end

        private

        def render_add_button
          div(class: "flex justify-end mb-4") do
            form(
              action: view_context.new_banking_category_path,
              method: "get",
              data: { turbo_stream: true },
              class: "inline"
            ) do
              button(
                type: "submit",
                class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2"
              ) do
                render ::Components::Icon::Add.new(size: "16", class: "mr-2")
                plain "Add Category"
              end
            end
          end
        end

        def render_categories_list
          if @categories.empty?
            div(class: "text-center py-8 text-muted-foreground") do
              plain "No categories yet. Click Add Category to create one."
            end
          else
            div(class: "divide-y divide-border rounded-md border") do
              @categories.each do |category|
                render_category_row(category)
              end
            end
          end
        end

        def render_category_row(category)
          div(
            id: "category_#{category.id}",
            class: "flex items-center justify-between p-3 hover:bg-muted/50"
          ) do
            div(class: "flex items-center gap-3") do
              render_color_swatch(category.color)
              span(class: "font-medium") { category.name }
              render_transaction_count(category)
            end
            div(class: "flex items-center gap-1") do
              render_edit_button(category)
              render_delete_button(category)
            end
          end
        end

        def render_color_swatch(color)
          div(
            class: "h-5 w-5 rounded-full border border-border",
            style: "background-color: #{color};"
          )
        end

        def render_transaction_count(category)
          count = category.bank_transactions.count
          if count > 0
            span(class: "text-xs text-muted-foreground") do
              plain "(#{count} transaction#{'s' if count != 1})"
            end
          end
        end

        def render_edit_button(category)
          form(
            action: view_context.edit_banking_category_path(category),
            method: "get",
            data: { turbo_stream: true },
            class: "inline"
          ) do
            button(
              type: "submit",
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 hover:bg-accent hover:text-accent-foreground h-8 w-8"
            ) do
              render ::Components::Icon::Edit.new(size: "16")
            end
          end
        end

        def render_delete_button(category)
          render AlertDialog.new do
            render AlertDialogTrigger.new do
              button(
                type: "button",
                class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 hover:bg-accent hover:text-accent-foreground h-8 w-8"
              ) do
                render ::Components::Icon::Trash.new(size: "16")
              end
            end

            render AlertDialogContent.new do
              render AlertDialogHeader.new do
                render AlertDialogTitle.new { "Delete \"#{category.name}\"?" }
                render AlertDialogDescription.new do
                  if category.bank_transactions.count > 0
                    plain "This will set #{category.bank_transactions.count} transaction(s) to Uncategorized. This action cannot be undone."
                  else
                    plain "This action cannot be undone."
                  end
                end
              end

              render AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                render AlertDialogCancel.new { "Cancel" }

                render RubyUI::Form.new(
                  action: view_context.banking_category_path(category),
                  method: "post",
                  data: { turbo_stream: true, action: "submit@document->ruby-ui--alert-dialog#dismiss" },
                  class: "inline"
                ) do
                  render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                  render RubyUI::Input.new(type: :hidden, name: "_method", value: "delete")
                  render AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                end
              end
            end
          end
        end
      end
    end
  end
end
