# frozen_string_literal: true

module Views
  module Banking
    module Goals
      class ProgressCards < ::Views::Base
        def initialize(goal_progress:)
          @goal_progress = goal_progress
        end

        def view_template
          return render_empty_state if @goal_progress.empty?

          div(class: "space-y-4") do
            @goal_progress.each do |progress|
              render_progress_card(progress)
            end
          end
        end

        private

        def render_empty_state
          div(class: "text-center py-8 rounded-lg border bg-card") do
            render ::Components::Icon::Target.new(size: "48", class: "mx-auto text-muted-foreground mb-4")
            p(class: "text-muted-foreground") { "No active goals" }
            button(
              type: "button",
              class: "mt-4 inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2",
              data: {
                controller: "enable-dialog",
                enable_dialog_url_value: view_context.new_banking_budget_goal_path,
                action: "click->enable-dialog#openDialog"
              }
            ) do
              render ::Components::Icon::Add.new(size: "16", class: "mr-2")
              plain "Create Goal"
            end
          end
        end

        def render_progress_card(progress)
          goal = progress.goal

          div(class: "rounded-lg border bg-card p-4 shadow-sm") do
            render_card_header(progress, goal)
            render_progress_visualization(progress, goal)
            render_card_footer(progress)
          end
        end

        def render_card_header(progress, goal)
          div(class: "flex items-start justify-between gap-2 mb-3") do
            div(class: "flex items-center gap-2 min-w-0") do
              if goal.savings?
                render ::Components::Icon::TrendingUp.new(size: "18", class: "text-green-500 flex-shrink-0")
              else
                div(
                  class: "w-4 h-4 rounded-full flex-shrink-0",
                  style: "background-color: #{goal.category&.color || '#6b7280'}"
                )
              end
              div(class: "min-w-0") do
                div(class: "font-medium text-sm truncate") { goal.display_name }
                div(class: "text-xs text-muted-foreground truncate") { short_period_label(goal) }
              end
            end

            div(class: "flex-shrink-0") do
              if progress.on_track
                Badge(variant: :success) { "On Track" }
              else
                Badge(variant: :destructive) { "Behind" }
              end
            end
          end
        end

        def short_period_label(goal)
          case goal.period
          when "custom"
            months = goal.effective_payment_months
            if months.size <= 4
              goal.period_label
            else
              "Custom (#{months.size} payments/year)"
            end
          else
            goal.period_label
          end
        end

        def render_progress_visualization(progress, goal)
          if goal.savings?
            render_savings_progress(progress)
          else
            render_bar_progress(progress)
          end
        end

        def render_savings_progress(progress)
          pct = progress.progress_percentage.clamp(0, 100)
          is_negative = progress.current_amount < 0

          div(class: "flex items-center gap-4") do
            div(class: "relative w-16 h-16 flex-shrink-0") do
              svg(
                class: "w-16 h-16 transform -rotate-90",
                viewBox: "0 0 100 100"
              ) do |s|
                s.circle(
                  cx: "50",
                  cy: "50",
                  r: "40",
                  stroke: "currentColor",
                  stroke_width: "10",
                  fill: "none",
                  class: "text-muted"
                )
                s.circle(
                  cx: "50",
                  cy: "50",
                  r: "40",
                  stroke: "currentColor",
                  stroke_width: "10",
                  fill: "none",
                  stroke_dasharray: "#{pct * 2.51} 251",
                  class: is_negative ? "text-red-500" : (progress.on_track ? "text-green-500" : "text-amber-500")
                )
              end
              div(class: "absolute inset-0 flex items-center justify-center") do
                span(class: "text-xs font-bold") do
                  if is_negative
                    plain "#{progress.progress_percentage.round}%"
                  else
                    plain "#{pct.round}%"
                  end
                end
              end
            end

            div(class: "flex-1 min-w-0") do
              div(class: "text-lg font-bold #{is_negative ? 'text-red-500' : ''}") do
                plain format_currency(progress.current_amount)
              end
              div(class: "text-xs text-muted-foreground") do
                plain "of #{format_currency(progress.target_amount)}"
              end
              if progress.remaining_amount > 0
                div(class: "text-xs text-muted-foreground mt-1") do
                  plain "#{format_currency(progress.remaining_amount)} to go"
                end
              end
            end
          end
        end

        def render_bar_progress(progress)
          pct = progress.progress_percentage.clamp(0, 100)

          div do
            div(class: "flex justify-between text-xs mb-1") do
              span(class: "font-medium") { format_currency(progress.current_amount) }
              span(class: "text-muted-foreground") { format_currency(progress.target_amount) }
            end

            div(class: "h-2 bg-muted rounded-full overflow-hidden") do
              bar_color = if progress.progress_percentage >= 100
                "bg-red-500"
              elsif progress.progress_percentage >= 80
                "bg-amber-500"
              else
                "bg-green-500"
              end

              div(
                class: "h-full #{bar_color} transition-all duration-300",
                style: "width: #{pct}%"
              )
            end

            div(class: "flex justify-between text-xs text-muted-foreground mt-1") do
              span { "#{progress.progress_percentage.round}% used" }
              span { "#{format_currency(progress.remaining_amount)} left" }
            end
          end
        end

        def render_card_footer(progress)
          div(class: "mt-3 pt-3 border-t space-y-2") do
            div(class: "flex justify-between text-xs text-muted-foreground") do
              span { "#{progress.days_elapsed}d elapsed" }
              span { "#{progress.days_remaining}d left" }
            end

            render_next_payment_info(progress) if progress.next_payment_date
          end
        end

        def render_next_payment_info(progress)
          next_date = progress.next_payment_date
          days_until = (next_date - Date.current).to_i

          urgency_class = if days_until <= 7
            "text-amber-600 dark:text-amber-400 bg-amber-100 dark:bg-amber-900/50"
          elsif days_until <= 30
            "text-blue-600 dark:text-blue-400 bg-blue-100 dark:bg-blue-900/50"
          else
            "text-muted-foreground bg-muted"
          end

          div(class: "p-2 rounded text-xs #{urgency_class}") do
            div(class: "flex items-center gap-1") do
              render ::Components::Icon::Calendar.new(size: "12", class: "flex-shrink-0")
              span do
                if days_until <= 0
                  plain "Due now!"
                elsif days_until == 1
                  plain "Due tomorrow"
                elsif days_until <= 7
                  plain "Due in #{days_until}d"
                else
                  plain next_date.strftime("%b %d")
                end
              end
            end

            if progress.upcoming_payments&.size&.> 1
              div(class: "text-[10px] mt-0.5 opacity-75") do
                upcoming = progress.upcoming_payments[1..2].map { |d| d.strftime("%b") }.join(", ")
                plain "Then: #{upcoming}"
              end
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
