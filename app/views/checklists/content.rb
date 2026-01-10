# frozen_string_literal: true

module Views
  module Checklists
    class Content < ::Views::Base
      def initialize(checklist:)
        @checklist = checklist
      end

      def view_template
        div(id: "checklist_content") do
          # Progress indicator
          render_progress

          # Items list
          div(class: "space-y-2 mt-6") do
            @checklist.items.each_with_index do |item, index|
              render ::Views::Checklists::Item.new(
                checklist: @checklist,
                item: item,
                item_index: index
              )
            end
          end

          # Reset button (if any items completed)
          if completed_count > 0
            div(class: "mt-6") do
              form(
                action: view_context.reset_checklist_path(@checklist),
                method: "post",
                data: {
                  turbo_stream: true,
                  controller: "form-loading",
                  form_loading_message_value: "Resetting checklist...",
                  action: "submit->form-loading#submit"
                }
              ) do
                csrf_token_field
                Button(variant: :outline, size: :md, type: :submit) do
                  render ::Components::Icon::Refresh.new(size: "16")
                  plain " Reset Checklist"
                end
              end
            end
          end
        end
      end

      private

      def completed_count
        @checklist.items.count { |item| item["completed_at"].present? }
      end

      def total_count
        @checklist.items.length
      end

      def progress_percentage
        return 0 if total_count.zero?
        ((completed_count.to_f / total_count) * 100).round
      end

      def render_progress
        div(class: "space-y-2") do
          # Progress text
          div(class: "flex items-center justify-between text-sm") do
            span(class: "font-medium") { "Progress" }
            span(class: "text-muted-foreground") do
              plain "#{completed_count}/#{total_count} complete"
            end
          end

          # Progress bar
          div(class: "h-2 bg-secondary rounded-full overflow-hidden") do
            div(
              class: "h-full bg-primary transition-all duration-300",
              style: "width: #{progress_percentage}%"
            )
          end

          # Flow type indicator
          div(class: "text-xs text-muted-foreground") do
            if @checklist.sequential?
              render ::Components::Icon::ArrowRight.new(size: "12", class: "inline")
              plain " Sequential - complete in order"
            else
              render ::Components::Icon::Grid.new(size: "12", class: "inline")
              plain " Parallel - complete in any order"
            end
          end
        end
      end
    end
  end
end
