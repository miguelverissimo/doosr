# frozen_string_literal: true

module Views
  module Banking
    module RecurringGroups
      class List < ::Views::Base
        include RubyUI

        def initialize(recurring_groups:, total_monthly:)
          @recurring_groups = recurring_groups
          @total_monthly = total_monthly
        end

        def view_template
          div(id: "recurring_groups_list", class: "space-y-4") do
            render_header
            render_total_monthly_card
            render_groups_list
          end
        end

        private

        def render_header
          div(class: "flex justify-between items-center mb-4") do
            div(id: "recurring_detection_errors")
            render_detect_button
          end
        end

        def render_detect_button
          render RubyUI::Form.new(
            action: helpers.detect_banking_recurring_groups_path,
            method: "post",
            data: { turbo_stream: true },
            class: "inline"
          ) do
            render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: helpers.form_authenticity_token)
            button(
              type: "submit",
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2"
            ) do
              render ::Components::Icon::Refresh.new(size: "16", class: "mr-2")
              plain "Detect Recurring"
            end
          end
        end

        def render_total_monthly_card
          div(class: "rounded-lg border bg-muted/50 p-4 mb-4") do
            div(class: "flex items-center justify-between") do
              div do
                span(class: "text-sm text-muted-foreground") { "Total Monthly Recurring" }
                div(class: "text-2xl font-bold #{@total_monthly >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}") do
                  plain format_currency(@total_monthly)
                end
              end
              div(class: "text-sm text-muted-foreground") do
                plain "#{@recurring_groups.size} recurring pattern#{'s' if @recurring_groups.size != 1}"
              end
            end
          end
        end

        def render_groups_list
          if @recurring_groups.empty?
            render_empty_state
          else
            div(class: "divide-y divide-border rounded-md border") do
              @recurring_groups.each do |group|
                render_group_row(group)
              end
            end
          end
        end

        def render_empty_state
          div(class: "text-center py-8 text-muted-foreground") do
            render ::Components::Icon::Repeat.new(size: "32", class: "mx-auto mb-3 opacity-50")
            p(class: "mb-2") { "No recurring patterns detected yet" }
            p(class: "text-sm") do
              plain "Click 'Detect Recurring' to analyze your transactions for recurring patterns"
            end
          end
        end

        def render_group_row(group)
          div(
            id: "recurring_group_#{group.id}",
            class: "p-4 hover:bg-muted/50 cursor-pointer",
            data: {
              controller: "recurring-group",
              recurring_group_url_value: helpers.banking_recurring_group_path(group),
              action: "click->recurring-group#showTransactions"
            }
          ) do
            div(class: "flex items-start justify-between") do
              div(class: "flex-1 min-w-0") do
                render_group_header(group)
                render_group_details(group)
              end
              render_group_stats(group)
            end
          end
        end

        def render_group_header(group)
          div(class: "flex items-center gap-2 mb-1") do
            span(class: "font-medium truncate") { group.name }
            render_frequency_badge(group.frequency)
          end
        end

        def render_group_details(group)
          div(class: "space-y-0.5") do
            span(class: "text-sm text-muted-foreground block") do
              plain "Pattern: "
              span(class: "font-mono") { group.description_pattern }
            end
            span(class: "text-xs text-muted-foreground") do
              plain "Last: #{group.last_occurrence.strftime('%b %d, %Y')}"
              if group.expected_next.present? && group.expected_next > Date.current
                plain " • Next expected: #{group.expected_next.strftime('%b %d, %Y')}"
              end
            end
          end
        end

        def render_group_stats(group)
          div(class: "text-right shrink-0 ml-4") do
            div(class: "text-lg font-semibold #{group.average_amount >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}") do
              plain format_currency(group.average_amount)
            end
            div(class: "text-xs text-muted-foreground") do
              plain "#{group.occurrence_count} occurrence#{'s' if group.occurrence_count != 1}"
            end
            div(class: "text-xs text-muted-foreground mt-1") do
              plain "~#{format_currency(group.monthly_amount)}/month"
            end
          end
        end

        def render_frequency_badge(frequency)
          color_class = case frequency
          when "weekly" then "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
          when "monthly" then "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
          when "yearly" then "bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200"
          else "bg-secondary text-secondary-foreground"
          end

          span(class: "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium #{color_class}") do
            plain frequency.capitalize
          end
        end

        def format_currency(amount)
          "€#{helpers.number_with_delimiter(sprintf('%.2f', amount))}"
        end
      end
    end
  end
end
