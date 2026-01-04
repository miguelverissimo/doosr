# frozen_string_literal: true

module Views
  module Admin
    module Notifications
      class LogEntry < ::Views::Base
        def initialize(log:)
          @log = log
        end

        def view_template
          div(class: "p-4 border rounded-lg bg-card #{status_class}") do
            div(class: "flex items-start justify-between") do
              div(class: "flex-1") do
                p(class: "text-sm font-medium") do
                  plain status_badge
                  plain " "
                  plain @log.notification_type.titleize
                end

                if @log.item
                  p(class: "text-xs text-muted-foreground mt-1") do
                    plain "Item: #{@log.item.title}"
                  end
                end

                p(class: "text-xs text-muted-foreground mt-1") do
                  plain @log.created_at.strftime("%b %d, %Y %H:%M:%S")
                end

                if @log.failed? && @log.error_message.present?
                  p(class: "text-xs text-red-600 mt-1") do
                    plain "Error: #{@log.error_message}"
                  end
                end
              end

              div(class: "text-right") do
                if @log.sent_at
                  p(class: "text-xs text-muted-foreground") do
                    plain "Sent: #{@log.sent_at.strftime('%H:%M:%S')}"
                  end
                end
              end
            end
          end
        end

        private

        def status_badge
          case @log.status
          when "sent"
            "✓"
          when "failed"
            "✗"
          when "pending"
            "⋯"
          else
            "?"
          end
        end

        def status_class
          case @log.status
          when "sent"
            "border-green-200"
          when "failed"
            "border-red-200"
          when "pending"
            "border-yellow-200"
          else
            ""
          end
        end
      end
    end
  end
end
