# frozen_string_literal: true

module Views
  module Items
    class RecurrenceOptions < ::Views::Base
      def initialize(item:, day: nil)
        @item = item
        @day = day
        @current_rule = parse_current_rule
      end

      def view_template
        div(id: "sheet_content_area", data: { controller: "recurrence-editor" }) do
          SheetHeader do
            SheetTitle(class: "text-left") { "Recurrence" }
            SheetDescription(class: "text-left text-xs text-muted-foreground") do
              @item.title
            end
          end

          SheetMiddle(class: "py-4") do
            # Main form without buttons
            render RubyUI::Form.new(
              id: "recurrence_form",
              action: update_recurrence_item_path(@item),
              method: "post",
              data: {
                turbo: "true",
                controller: "form-loading",
                form_loading_message_value: "Updating recurrence...",
                recurrence_editor_target: "form"
              },
              class: "flex flex-col gap-4"
            ) do
              # Hidden fields - MUST use RubyUI::Input
              render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
              render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch")
              render RubyUI::Input.new(type: :hidden, name: "day_id", value: @day&.id)
              render RubyUI::Input.new(
                type: :hidden,
                name: "recurrence_rule",
                data: { recurrence_editor_target: "ruleInput" },
                value: @item.recurrence_rule || "none"
              )

              # Recurrence type selector
              div(class: "space-y-2") do
                label(class: "text-sm font-medium") { "Repeat" }

                # Segmented control for frequency
                div(class: "grid grid-cols-4 gap-2") do
                  render_frequency_option("None", "none")
                  render_frequency_option("Daily", "daily")
                  render_frequency_option("Weekdays", "every_weekday")
                  render_frequency_option("Weekly", "weekly")
                end

                div(class: "grid grid-cols-3 gap-2 mt-2") do
                  render_frequency_option("Every X Days", "every_n_days")
                  render_frequency_option("Monthly", "monthly")
                  render_frequency_option("Yearly", "yearly")
                end
              end

              # Every N Days interval input (hidden by default)
              div(
                class: "space-y-2 #{"hidden" unless @current_rule[:frequency] == "every_n_days"}",
                data: { recurrence_editor_target: "intervalContainer" }
              ) do
                render RubyUI::FormField.new do
                  render RubyUI::FormFieldLabel.new { "Repeat every:" }
                  div(class: "flex items-center gap-2") do
                    render RubyUI::Input.new(
                      type: :number,
                      min: "1",
                      max: "365",
                      value: (@current_rule[:interval] || 3).to_s,
                      data: {
                        recurrence_editor_target: "intervalInput",
                        action: "input->recurrence-editor#updateInterval"
                      },
                      class: "w-20"
                    )
                    span(class: "text-sm text-muted-foreground") { "days" }
                  end
                  render RubyUI::FormFieldError.new
                end
              end

              # Weekly days selector (hidden by default)
              div(
                class: "space-y-2 #{"hidden" unless @current_rule[:frequency] == "weekly"}",
                data: { recurrence_editor_target: "weeklyContainer" }
              ) do
                label(class: "text-sm font-medium") { "Repeat on:" }
                div(class: "flex gap-2") do
                  render_weekday_pill("Sun", 0)
                  render_weekday_pill("Mon", 1)
                  render_weekday_pill("Tue", 2)
                  render_weekday_pill("Wed", 3)
                  render_weekday_pill("Thu", 4)
                  render_weekday_pill("Fri", 5)
                  render_weekday_pill("Sat", 6)
                end
              end
            end

            # Action Buttons - outside main form
            div(class: "flex justify-center items-center gap-3 mt-4") do
              # Save button associated with main form via form attribute
              Button(type: :submit, variant: :primary, form: "recurrence_form") { "Save" }

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

      private

      def parse_current_rule
        return { frequency: "none" } if @item.recurrence_rule.blank?

        rule = @item.recurrence_rule.is_a?(String) ? JSON.parse(@item.recurrence_rule) : @item.recurrence_rule
        rule.symbolize_keys
      rescue JSON::ParserError
        { frequency: "none" }
      end

      def render_frequency_option(label, frequency)
        selected = @current_rule[:frequency] == frequency
        button(
          type: "button",
          data: {
            action: "click->recurrence-editor#selectFrequency",
            recurrence_editor_frequency_param: frequency
          },
          class: [
            "h-10 px-3 rounded-md text-sm font-medium transition-colors",
            selected ? "bg-primary text-primary-foreground" : "border bg-background hover:bg-accent"
          ].join(" ")
        ) do
          label
        end
      end

      def render_weekday_pill(day_label, day_num)
        selected = @current_rule[:frequency] == "weekly" &&
                   @current_rule[:days_of_week]&.include?(day_num)

        button(
          type: "button",
          data: {
            action: "click->recurrence-editor#toggleWeekday",
            recurrence_editor_day_param: day_num
          },
          class: [
            "w-10 h-10 rounded-full text-sm font-medium transition-colors",
            selected ? "bg-primary text-primary-foreground" : "border bg-background hover:bg-accent"
          ].join(" ")
        ) do
          day_label
        end
      end
    end
  end
end
