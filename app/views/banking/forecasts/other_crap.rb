# frozen_string_literal: true

module Views
  module Banking
    module Forecasts
      class OtherCrap < ::Views::Base
        def initialize(user:, forecast:)
          @user = user
          @forecast = forecast
        end

        def view_template
          div(class: "flex h-full flex-col space-y-6") do
            render_header
            render_summary_section
            render_main_content
          end
        end

        private

        def render_header
          div(class: "flex items-center justify-between") do
            div do
              h1(class: "text-2xl font-bold") { "Other Crap" }
              p(class: "text-muted-foreground") { "Balance projections, goals, and suggestions" }
            end
            div(class: "flex items-center gap-2") do
              render_back_to_forecast_button
              render_goals_button
              render_expenses_button
              render_reminders_button
              render_calendar_button
            end
          end
        end

        def render_back_to_forecast_button
          a(
            href: view_context.banking_forecasts_path,
            class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2"
          ) do
            render ::Components::Icon::ArrowLeft.new(size: "16", class: "mr-2")
            plain "Back to Forecast"
          end
        end

        def render_goals_button
          button(
            type: "button",
            class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2",
            data: {
              controller: "enable-dialog",
              enable_dialog_url_value: view_context.banking_budget_goals_path,
              action: "click->enable-dialog#openDialog"
            }
          ) do
            render ::Components::Icon::Target.new(size: "16", class: "mr-2")
            plain "Goals"
          end
        end

        def render_expenses_button
          button(
            type: "button",
            class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2",
            data: {
              controller: "enable-dialog",
              enable_dialog_url_value: view_context.banking_planned_expenses_path,
              action: "click->enable-dialog#openDialog"
            }
          ) do
            render ::Components::Icon::Calendar.new(size: "16", class: "mr-2")
            plain "Expenses"
          end
        end

        def render_reminders_button
          button(
            type: "button",
            class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2",
            data: {
              controller: "enable-dialog",
              enable_dialog_url_value: view_context.banking_payment_reminders_path,
              action: "click->enable-dialog#openDialog"
            }
          ) do
            render ::Components::Icon::CreditCard.new(size: "16", class: "mr-2")
            plain "Reminders"
          end
        end

        def render_calendar_button
          button(
            type: "button",
            class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2",
            data: {
              controller: "enable-dialog",
              enable_dialog_url_value: view_context.calendar_banking_forecasts_path,
              action: "click->enable-dialog#openDialog"
            }
          ) do
            render ::Components::Icon::Grid.new(size: "16", class: "mr-2")
            plain "Calendar View"
          end
        end

        def render_summary_section
          div(class: "grid gap-4 md:grid-cols-3") do
            render_balance_card
            render_projected_income_card
            render_projected_expenses_card
          end
        end

        def render_balance_card
          div(class: "rounded-lg border bg-card p-6 shadow-sm") do
            div(class: "flex items-center gap-2 pb-2") do
              render ::Components::Icon::CurrencyEuro.new(size: "20", class: "text-muted-foreground")
              h3(class: "text-sm font-medium text-muted-foreground") { "Current Balance" }
            end
            div(class: "text-2xl font-bold") { format_currency(@forecast.current_balance) }
          end
        end

        def render_projected_income_card
          total_income = @forecast.weekly_projections.sum(&:recurring_income)
          div(class: "rounded-lg border bg-card p-6 shadow-sm") do
            div(class: "flex items-center gap-2 pb-2") do
              render ::Components::Icon::TrendingUp.new(size: "20", class: "text-green-500")
              h3(class: "text-sm font-medium text-muted-foreground") { "Projected Income (12 wks)" }
            end
            div(class: "text-2xl font-bold text-green-600 dark:text-green-400") do
              plain format_currency(total_income)
            end
          end
        end

        def render_projected_expenses_card
          total_expenses = @forecast.weekly_projections.sum do |p|
            p.recurring_expenses + p.planned_expenses + p.variable_spending
          end
          div(class: "rounded-lg border bg-card p-6 shadow-sm") do
            div(class: "flex items-center gap-2 pb-2") do
              render ::Components::Icon::ArrowDown.new(size: "20", class: "text-red-500")
              h3(class: "text-sm font-medium text-muted-foreground") { "Projected Expenses (12 wks)" }
            end
            div(class: "text-2xl font-bold text-red-600 dark:text-red-400") do
              plain format_currency(total_expenses)
            end
          end
        end

        def render_main_content
          div(class: "grid gap-6 lg:grid-cols-[2fr_1fr]") do
            div(class: "space-y-6 min-w-0") do
              render ::Views::Banking::Forecasts::ProjectionsChart.new(
                projections: @forecast.weekly_projections,
                current_balance: @forecast.current_balance
              )
              render_warnings_and_suggestions
            end
            div(class: "space-y-4") do
              render_goals_section
            end
          end
        end

        def render_goals_section
          div(class: "rounded-lg border bg-card shadow-sm") do
            div(class: "flex items-center justify-between p-4 border-b") do
              div(class: "flex items-center gap-2") do
                render ::Components::Icon::Target.new(size: "18")
                h3(class: "font-semibold text-sm") { "Goals" }
              end
              button(
                type: "button",
                class: "text-xs text-primary hover:underline",
                data: {
                  controller: "enable-dialog",
                  enable_dialog_url_value: view_context.banking_budget_goals_path,
                  action: "click->enable-dialog#openDialog"
                }
              ) { "Manage" }
            end
            div(class: "p-4") do
              render ::Views::Banking::Goals::ProgressCards.new(goal_progress: @forecast.goal_progress)
            end
          end
        end

        def render_warnings_and_suggestions
          return if @forecast.warnings.empty? && @forecast.suggestions.empty?

          has_both = @forecast.warnings.any? && @forecast.suggestions.any?

          div(class: has_both ? "grid gap-4 md:grid-cols-2" : "") do
            render ::Views::Banking::Forecasts::WarningsPanel.new(warnings: @forecast.warnings) if @forecast.warnings.any?
            render ::Views::Banking::Forecasts::SuggestionsPanel.new(suggestions: @forecast.suggestions) if @forecast.suggestions.any?
          end
        end

        def format_currency(amount)
          "#{view_context.number_with_delimiter(sprintf('%.2f', amount))}"
        end
      end
    end
  end
end
