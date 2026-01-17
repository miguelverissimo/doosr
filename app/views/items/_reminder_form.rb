# frozen_string_literal: true

module Views
  module Items
    class ReminderForm < ::Views::Base
      def initialize(item:, day: nil)
        @item = item
        @day = day
      end

      def view_template
        div(id: "sheet_content_area", data: { controller: "reminder-form" }) do
          SheetHeader do
            SheetTitle(class: "text-left") { "Add Reminder" }
            SheetDescription(class: "text-left text-xs text-muted-foreground") do
              @item.title
            end
          end

          SheetMiddle(class: "py-4") do
            render_form
          end
        end
      end

      private

      def render_form
        Form(
          id: "reminder_form",
          action: "/items/#{@item.id}/notifications",
          method: :post,
          data: { turbo: "true" }
        ) do
          csrf_token_field
          Input(type: :hidden, name: "day_id", value: @day&.id)

          div(class: "flex flex-col gap-4") do
            render_preset_buttons
            render_datetime_input
          end
        end

        render_action_buttons
      end

      def render_preset_buttons
        div(class: "flex flex-col gap-2") do
          p(class: "text-sm font-medium text-muted-foreground") { "Quick presets" }
          div(class: "flex gap-2") do
            render_preset_button("In 1 hour", "in_1_hour")
            render_preset_button("Tomorrow 9am", "tomorrow_9am")
            render_preset_button("In 3 days", "in_3_days")
          end
        end
      end

      def render_preset_button(label, preset)
        Button(
          type: :button,
          variant: :outline,
          size: :sm,
          class: "flex-1",
          data: {
            action: "click->reminder-form#setPreset",
            preset: preset
          }
        ) { label }
      end

      def render_datetime_input
        div(class: "flex flex-col gap-2") do
          FormField do
            FormFieldLabel(for: "remind_at") { "Reminder date and time" }
            Input(
              type: "datetime-local",
              id: "remind_at",
              name: "remind_at",
              required: true,
              class: "date-input-icon-light-dark",
              data: {
                reminder_form_target: "datetimeInput",
                action: "input->reminder-form#validateDateTime change->reminder-form#validateDateTime"
              }
            )
          end
        end
      end

      def render_action_buttons
        div(class: "flex justify-center items-center gap-3 mt-4") do
          Button(
            type: :submit,
            variant: :primary,
            disabled: true,
            form: "reminder_form",
            data: { reminder_form_target: "submitButton" }
          ) { "Save Reminder" }

          Button(
            type: :button,
            variant: :outline,
            data: {
              controller: "drawer-back",
              drawer_back_url_value: actions_sheet_item_path(@item, day_id: @day&.id, from_edit_form: true),
              action: "click->drawer-back#goBack"
            }
          ) { "Cancel" }
        end
      end
    end
  end
end
