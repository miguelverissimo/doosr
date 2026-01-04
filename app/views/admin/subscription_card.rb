# frozen_string_literal: true

module Views
  module Admin
    class SubscriptionCard < ::Views::Base
      def initialize(subscription:, user:)
        @subscription = subscription
        @user = user
      end

      def view_template
        div(class: "p-4 border rounded-lg bg-card") do
          div(class: "flex items-center justify-between") do
            div(class: "flex-1") do
              p(class: "text-sm font-medium") { truncate_user_agent(@subscription.user_agent) }
              p(class: "text-xs text-muted-foreground mt-1") do
                plain "Created: #{@subscription.created_at.strftime('%b %d, %Y %H:%M')}"
              end
              if @subscription.last_used_at
                p(class: "text-xs text-muted-foreground") do
                  plain "Last used: #{time_ago_in_words(@subscription.last_used_at)} ago"
                end
              end
            end

            form(
              action: view_context.send_to_device_admin_notification_path(@subscription),
              method: "post",
              data: { turbo_stream: true }
            ) do
              view_context.hidden_field_tag :authenticity_token, view_context.form_authenticity_token

              button(
                type: "submit",
                class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-3"
              ) { "Test Device" }
            end
          end
        end
      end

      private

      def truncate_user_agent(user_agent)
        return "Unknown Device" if user_agent.blank?
        user_agent.length > 50 ? "#{user_agent[0..47]}..." : user_agent
      end

      def time_ago_in_words(time)
        view_context.time_ago_in_words(time)
      end
    end
  end
end
