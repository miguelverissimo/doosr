# frozen_string_literal: true

module Views
  module Banking
    module Forecasts
      class Index < ::Views::Base
        def initialize(user:, payment_reminders:, paid_status:, section_spending:)
          @user = user
          @payment_reminders = payment_reminders
          @paid_status = paid_status || {}
          @section_spending = section_spending
        end

        def view_template
          div(class: "flex h-full flex-col space-y-6") do
            render_header
            render_main_content
          end
        end

        private

        def render_header
          div(class: "flex items-center justify-between") do
            div do
              h1(class: "text-2xl font-bold") { "Financial Forecast" }
              p(class: "text-muted-foreground") { "Upcoming payments and spending limits" }
            end
            div(class: "flex items-center gap-2") do
              render_back_to_banking_button
              render_other_crap_button
              render_reminders_button
            end
          end
        end

        def render_back_to_banking_button
          a(
            href: view_context.banking_index_path,
            class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2"
          ) do
            render ::Components::Icon::ArrowLeft.new(size: "16", class: "mr-2")
            plain "Back to Banking"
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

        def render_other_crap_button
          a(
            href: view_context.other_crap_banking_forecasts_path,
            class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2"
          ) do
            render ::Components::Icon::BarChart.new(size: "16", class: "mr-2")
            plain "Other Crap"
          end
        end

        def render_main_content
          render ::Views::Banking::Forecasts::MainContent.new(
            payment_reminders: @payment_reminders,
            paid_status: @paid_status,
            section_spending: @section_spending
          )
        end
      end
    end
  end
end
