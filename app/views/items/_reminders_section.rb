# frozen_string_literal: true

module Views
  module Items
    class RemindersSection < ::Views::Base
      def initialize(item:, day: nil)
        @item = item
        @day = day
        @pending_reminders = @item.notifications.pending.order(:remind_at)
      end

      def view_template
        div(id: "sheet_content_area") do
          SheetHeader do
            SheetTitle(class: "text-left") { "Reminders" }
            SheetDescription(class: "text-left text-xs text-muted-foreground") do
              @item.title
            end
          end

          SheetMiddle(class: "py-4") do
            div(class: "flex flex-col gap-4") do
              render_reminders_list

              render_action_buttons
            end
          end
        end
      end

      private

      def render_reminders_list
        div(id: "reminders_list_#{@item.id}", class: "flex flex-col gap-2") do
          if @pending_reminders.any?
            @pending_reminders.each do |notification|
              render_reminder_row(notification)
            end
          else
            div(class: "text-center py-8 text-muted-foreground text-sm") do
              "No reminders set"
            end
          end
        end
      end

      def render_reminder_row(notification)
        div(
          id: "reminder_#{notification.id}",
          class: "flex items-center justify-between rounded-lg border bg-card p-3"
        ) do
          div(class: "flex flex-col") do
            p(class: "font-medium text-sm") do
              notification.remind_at.strftime("%b %-d, %Y")
            end
            p(class: "text-xs text-muted-foreground") do
              notification.remind_at.strftime("%-I:%M %p")
            end
          end

          render RubyUI::AlertDialog.new do
            render RubyUI::AlertDialogTrigger.new do
              Button(
                type: :button,
                variant: :ghost,
                icon: true,
                size: :sm,
                class: "h-8 w-8 text-muted-foreground hover:text-destructive"
              ) do
                render ::Components::Icon::X.new(size: "16")
              end
            end

            render RubyUI::AlertDialogContent.new do
              render RubyUI::AlertDialogHeader.new do
                render RubyUI::AlertDialogTitle.new { "Delete this reminder?" }
                render RubyUI::AlertDialogDescription.new { "This action cannot be undone." }
              end

              render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                render RubyUI::AlertDialogCancel.new { "Cancel" }

                form(
                  action: view_context.notification_path(notification, day_id: @day&.id),
                  method: "post",
                  data: { turbo_stream: true, action: "submit@document->ruby-ui--alert-dialog#dismiss" },
                  class: "inline"
                ) do
                  csrf_token_field
                  input(type: "hidden", name: "_method", value: "delete")
                  render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                end
              end
            end
          end
        end
      end

      def render_action_buttons
        div(class: "flex justify-center items-center gap-3 mt-4") do
          Button(
            type: :button,
            variant: :primary,
            data: {
              controller: "drawer-back",
              drawer_back_url_value: reminder_form_item_path(@item, day_id: @day&.id),
              action: "click->drawer-back#goBack"
            }
          ) { "Add Reminder" }

          Button(
            type: :button,
            variant: :outline,
            data: {
              controller: "drawer-back",
              drawer_back_url_value: actions_sheet_item_path(@item, day_id: @day&.id, from_edit_form: true),
              action: "click->drawer-back#goBack"
            }
          ) { "Back" }
        end
      end
    end
  end
end
