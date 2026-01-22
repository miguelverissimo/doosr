# frozen_string_literal: true

module Views
  module DayPaymentReminders
    class ActionsSheetButtons < ::Views::Base
      def initialize(day_payment_reminder:, day: nil, list: nil, reminder_index: nil, total_reminders: nil, day_is_closed: false)
        @day_payment_reminder = day_payment_reminder
        @day = day
        @list = list
        @reminder_index = reminder_index
        @total_reminders = total_reminders
        @day_is_closed = day_is_closed
      end

      def view_template
        div(id: "action_sheet_buttons_#{@day_payment_reminder.id}", class: "flex items-center justify-between gap-2") do
          # Left side - primary actions
          div(class: "flex items-center gap-2") do
            # Mark Paid button (only show if not already paid)
            unless @day_payment_reminder.paid?
              render_icon_button(
                icon: :check,
                action: view_context.mark_paid_day_payment_reminder_path(@day_payment_reminder),
                method: "patch",
                params: { "day_id" => @day&.id, "list_id" => @list&.id },
                disabled: @day_is_closed,
                variant: :primary,
                loading_message: "Marking as paid..."
              )
            end

            # Edit payment reminder (opens the payment reminder edit dialog)
            Button(
              href: view_context.edit_banking_payment_reminder_path(@day_payment_reminder.payment_reminder),
              variant: :outline,
              icon: true,
              size: :md,
              data: { turbo_stream: true }
            ) do
              render ::Components::Icon::Edit.new(size: "20")
            end

            # Delete (remove from day)
            if @day_is_closed
              Button(
                variant: :outline,
                icon: true,
                size: :md,
                disabled: true,
                class: "opacity-50"
              ) do
                render ::Components::Icon::Trash.new(size: "20")
              end
            else
              Button(
                variant: :outline,
                icon: true,
                size: :md,
                type: :button,
                class: "border-destructive text-destructive hover:bg-destructive hover:text-destructive-foreground",
                data: {
                  controller: "day-payment-reminder",
                  day_payment_reminder_id_value: @day_payment_reminder.id,
                  day_payment_reminder_day_id_value: @day&.id,
                  day_payment_reminder_list_id_value: @list&.id,
                  action: "click->day-payment-reminder#confirmDelete"
                }
              ) do
                render ::Components::Icon::Trash.new(size: "20")
              end
            end
          end

          # Right side - move actions
          div(class: "flex items-center gap-2") do
            # Move Up
            can_move_up = @reminder_index && @reminder_index > 0 && !@day_is_closed
            render_icon_button(
              icon: :arrow_up,
              action: view_context.move_day_payment_reminder_path(@day_payment_reminder),
              method: "patch",
              params: { "direction" => "up", "day_id" => @day&.id, "list_id" => @list&.id },
              disabled: !can_move_up,
              loading_message: "Moving payment reminder up..."
            )

            # Move Down
            can_move_down = @reminder_index && @total_reminders && @reminder_index < (@total_reminders - 1) && !@day_is_closed
            render_icon_button(
              icon: :arrow_down,
              action: view_context.move_day_payment_reminder_path(@day_payment_reminder),
              method: "patch",
              params: { "direction" => "down", "day_id" => @day&.id, "list_id" => @list&.id },
              disabled: !can_move_down,
              loading_message: "Moving payment reminder down..."
            )
          end
        end
      end

      private

      def render_icon_button(icon:, action: nil, method: "post", params: {}, disabled: false, variant: :default, loading_message: "Processing...")
        if disabled
          Button(
            variant: :outline,
            icon: true,
            size: :md,
            disabled: true,
            class: "opacity-50"
          ) do
            icon_class = ::Components::Icon::Base.for(icon)
            render icon_class.new(size: "20")
          end
        else
          form(
            action: action,
            method: "post",
            data: {
              controller: "form-loading",
              form_loading_message_value: loading_message,
              turbo: true,
              turbo_stream: true
            },
            class: "inline-block"
          ) do
            csrf_token_field
            input(type: "hidden", name: "_method", value: method) if method != "post"

            params.each do |key, value|
              input(type: "hidden", name: key, value: value) if value.present?
            end

            button_variant = case variant
            when :destructive then :destructive
            when :primary then :primary
            else :outline
            end

            Button(
              variant: button_variant,
              icon: true,
              size: :md,
              type: :submit
            ) do
              icon_class = ::Components::Icon::Base.for(icon)
              render icon_class.new(size: "20")
            end
          end
        end
      end
    end
  end
end
