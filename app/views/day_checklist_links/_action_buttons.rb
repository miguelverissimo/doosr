# frozen_string_literal: true

module Views
  module DayChecklistLinks
    class ActionButtons < ::Views::Base
      def initialize(checklist:, day:, item_index: nil, total_items: nil)
        @checklist = checklist
        @day = day
        @item_index = item_index
        @total_items = total_items
      end

      def view_template
        div(id: "action_sheet_buttons_checklist_#{@checklist.id}", class: "flex items-center justify-between gap-2") do
          # Left side - primary actions
          div(class: "flex items-center gap-2") do
            # Open Checklist
            a(
              href: checklist_path(@checklist),
              class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
            ) do
              render ::Components::Icon.new(name: :checklist, size: "20")
            end

            # Remove from Day
            if @day.closed?
              button(
                type: "button",
                disabled: true,
                class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
              ) do
                render ::Components::Icon.new(name: :delete, size: "20")
              end
            else
              form(
                action: day_checklist_link_path(@checklist, day_id: @day.id),
                method: "post",
                data: {
                  controller: "form-loading",
                  form_loading_message_value: "Removing...",
                  turbo: "true"
                },
                class: "inline-block"
              ) do
                csrf_token_field
                input(type: "hidden", name: "_method", value: "delete")

                button(
                  type: "submit",
                  class: "flex h-10 w-10 items-center justify-center rounded-lg border border-destructive text-destructive hover:bg-destructive hover:text-destructive-foreground transition-colors"
                ) do
                  render ::Components::Icon.new(name: :delete, size: "20")
                end
              end
            end
          end

          # Right side - utility actions
          div(class: "flex items-center gap-2") do
            # Move Up
            can_move_up = @item_index && @item_index > 0 && !@day.closed?
            if can_move_up
              form(
                action: move_day_checklist_link_path(@checklist, day_id: @day.id, direction: "up"),
                method: "post",
                data: {
                  controller: "form-loading",
                  form_loading_message_value: "Moving...",
                  turbo: "true"
                },
                class: "inline-block"
              ) do
                csrf_token_field
                input(type: "hidden", name: "_method", value: "patch")

                button(
                  type: "submit",
                  class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
                ) do
                  render ::Components::Icon.new(name: :arrow_up, size: "20")
                end
              end
            else
              button(
                type: "button",
                disabled: true,
                class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
              ) do
                render ::Components::Icon.new(name: :arrow_up, size: "20")
              end
            end

            # Move Down
            can_move_down = @item_index && @total_items && @item_index < (@total_items - 1) && !@day.closed?
            if can_move_down
              form(
                action: move_day_checklist_link_path(@checklist, day_id: @day.id, direction: "down"),
                method: "post",
                data: {
                  controller: "form-loading",
                  form_loading_message_value: "Moving...",
                  turbo: "true"
                },
                class: "inline-block"
              ) do
                csrf_token_field
                input(type: "hidden", name: "_method", value: "patch")

                button(
                  type: "submit",
                  class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors"
                ) do
                  render ::Components::Icon.new(name: :arrow_down, size: "20")
                end
              end
            else
              button(
                type: "button",
                disabled: true,
                class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-muted text-muted-foreground opacity-50"
              ) do
                render ::Components::Icon.new(name: :arrow_down, size: "20")
              end
            end

            # Debug - ALWAYS ACTIVE
            if Rails.env.development?
              button(
                type: "button",
                class: "flex h-10 w-10 items-center justify-center rounded-lg border bg-background hover:bg-accent transition-colors",
                data: {
                  controller: "checklist-link",
                  checklist_link_id_value: @checklist.id,
                  checklist_link_day_id_value: @day.id,
                  action: "click->checklist-link#openDebug",
                  checklist_id: @checklist.id,
                  day_id: @day.id
                }
              ) do
                render ::Components::Icon.new(name: :bug, size: "20")
              end
            end
          end
        end
      end
    end
  end
end
