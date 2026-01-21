# frozen_string_literal: true

module Views
  module Banking
    module Goals
      class IndexDialog < ::Views::Base
        def initialize(budget_goals:, categories:)
          @budget_goals = budget_goals
          @categories = categories
        end

        def view_template
          div(id: "budget_goals_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Budget Goals" }
                  render RubyUI::DialogDescription.new { "Manage your savings targets and category spending limits" }
                end

                render RubyUI::DialogMiddle.new do
                  div(id: "budget_goals_content") do
                    render_goals_list
                  end
                end
              end
            end
          end
        end

        private

        def render_goals_list
          if @budget_goals.empty?
            render_empty_state
          else
            div(class: "space-y-3") do
              @budget_goals.each do |goal|
                render_goal_item(goal)
              end
            end
          end

          render_add_button
        end

        def render_empty_state
          div(class: "text-center py-8") do
            render ::Components::Icon::Target.new(size: "48", class: "mx-auto text-muted-foreground mb-4")
            p(class: "text-muted-foreground") { "No budget goals yet" }
            p(class: "text-sm text-muted-foreground") { "Create your first savings target or category budget limit" }
          end
        end

        def render_goal_item(goal)
          div(
            id: "budget_goal_#{goal.id}",
            class: "flex items-center justify-between p-4 rounded-lg border bg-card"
          ) do
            div(class: "flex items-center gap-3") do
              render_goal_icon(goal)
              div do
                div(class: "font-medium") { goal.display_name }
                div(class: "text-sm text-muted-foreground") do
                  plain "#{format_currency(goal.target_amount)} / #{goal.period_label}"
                end
                render_next_payment(goal) if goal.next_payment_date
              end
            end

            div(class: "flex items-center gap-2") do
              render_status_badge(goal)
              render_edit_button(goal)
              render_delete_button(goal)
            end
          end
        end

        def render_next_payment(goal)
          next_date = goal.next_payment_date
          return unless next_date

          days_until = (next_date - Date.current).to_i
          text = if days_until <= 0
            "Due now"
          elsif days_until == 1
            "Due tomorrow"
          elsif days_until <= 7
            "Due in #{days_until} days"
          else
            "Next: #{next_date.strftime('%b %d')}"
          end

          div(class: "text-xs mt-1") do
            span(class: days_until <= 7 ? "text-amber-600 dark:text-amber-400" : "text-muted-foreground") do
              render ::Components::Icon::Calendar.new(size: "12", class: "inline mr-1")
              plain text
            end
          end
        end

        def render_goal_icon(goal)
          if goal.savings?
            render ::Components::Icon::TrendingUp.new(size: "20", class: "text-green-500")
          else
            div(
              class: "w-5 h-5 rounded-full",
              style: "background-color: #{goal.category&.color || '#6b7280'}"
            )
          end
        end

        def render_status_badge(goal)
          if goal.active?
            Badge(variant: :success) { "Active" }
          else
            Badge(variant: :secondary) { "Inactive" }
          end
        end

        def render_edit_button(goal)
          button(
            type: "button",
            class: "p-2 rounded-md hover:bg-accent",
            data: {
              controller: "enable-dialog",
              enable_dialog_url_value: view_context.edit_banking_budget_goal_path(goal),
              action: "click->enable-dialog#openDialog"
            }
          ) do
            render ::Components::Icon::Edit.new(size: "16")
          end
        end

        def render_delete_button(goal)
          button(
            type: "button",
            class: "p-2 rounded-md hover:bg-destructive/10 text-destructive",
            data: {
              controller: "delete-confirm",
              delete_confirm_url_value: view_context.banking_budget_goal_path(goal),
              delete_confirm_message_value: "Are you sure you want to delete this goal?",
              action: "click->delete-confirm#confirm"
            }
          ) do
            render ::Components::Icon::Trash.new(size: "16")
          end
        end

        def render_add_button
          div(class: "mt-4") do
            button(
              type: "button",
              class: "w-full inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-dashed border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2",
              data: {
                controller: "enable-dialog",
                enable_dialog_url_value: view_context.new_banking_budget_goal_path,
                action: "click->enable-dialog#openDialog"
              }
            ) do
              render ::Components::Icon::Add.new(size: "16", class: "mr-2")
              plain "Add Goal"
            end
          end
        end

        def format_currency(amount)
          "#{view_context.number_with_delimiter(sprintf('%.2f', amount))}"
        end
      end
    end
  end
end
