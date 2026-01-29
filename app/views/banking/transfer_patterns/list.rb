# frozen_string_literal: true

module Views
  module Banking
    module TransferPatterns
      class List < ::Views::Base
        include RubyUI

        def initialize(transfer_patterns:)
          @transfer_patterns = transfer_patterns
        end

        def view_template
          div(id: "transfer_patterns_content", class: "space-y-4") do
            render_add_button
            render_patterns_list
          end
        end

        private

        def render_add_button
          div(class: "flex justify-end mb-4") do
            button(
              type: "button",
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2",
              data: {
                controller: "turbo-fetch",
                turbo_fetch_url_value: view_context.new_banking_transfer_pattern_path,
                action: "click->turbo-fetch#load"
              }
            ) do
              render ::Components::Icon::Add.new(size: "16", class: "mr-2")
              plain "Add Pattern"
            end
          end
        end

        def render_patterns_list
          if @transfer_patterns.empty?
            div(class: "text-center py-8 text-muted-foreground") do
              p { "No transfer patterns yet." }
              p(class: "text-sm mt-2") do
                plain "Common patterns include: TRANSFER, TRF TO, TRF FROM, INTERNAL"
              end
            end
          else
            div(class: "divide-y divide-border rounded-md border") do
              @transfer_patterns.each do |pattern|
                render_pattern_row(pattern)
              end
            end
          end
        end

        def render_pattern_row(pattern)
          div(
            id: "transfer_pattern_#{pattern.id}",
            class: "flex items-center justify-between p-3 hover:bg-muted/50"
          ) do
            div(class: "flex-1 min-w-0") do
              div(class: "flex items-center gap-3 mb-1") do
                span(class: "font-mono text-sm font-medium truncate") { pattern.pattern }
                if pattern.label.present?
                  span(class: "text-xs text-muted-foreground") { pattern.label }
                end
                render_transfer_badge
              end
              render_match_count(pattern)
            end
            div(class: "flex items-center gap-1 ml-2 shrink-0") do
              render_edit_button(pattern)
              render_delete_button(pattern)
            end
          end
        end

        def render_transfer_badge
          div(class: "inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200") do
            render ::Components::Icon::ArrowLeftRight.new(size: "12")
            span { "Transfer" }
          end
        end

        def render_match_count(pattern)
          count = pattern.matched_transactions_count
          span(class: "text-xs text-muted-foreground") do
            plain "Matches #{count} transaction#{'s' if count != 1}"
          end
        end

        def render_edit_button(pattern)
          button(
            type: "button",
            class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 hover:bg-accent hover:text-accent-foreground h-8 w-8",
            data: {
              controller: "turbo-fetch",
              turbo_fetch_url_value: view_context.edit_banking_transfer_pattern_path(pattern),
              action: "click->turbo-fetch#load"
            }
          ) do
            render ::Components::Icon::Edit.new(size: "16")
          end
        end

        def render_delete_button(pattern)
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
                render AlertDialogTitle.new { "Delete pattern \"#{pattern.pattern}\"?" }
                render AlertDialogDescription.new do
                  plain "This will remove the transfer pattern. Matching transactions will be unmarked as transfers."
                end
              end

              render AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                render AlertDialogCancel.new { "Cancel" }

                render RubyUI::Form.new(
                  action: view_context.banking_transfer_pattern_path(pattern),
                  method: "post",
                  data: {
                    controller: "form-loading",
                    form_loading_message_value: "Deleting pattern...",
                    turbo_stream: true,
                    action: "submit@document->ruby-ui--alert-dialog#dismiss"
                  },
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
