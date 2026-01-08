# frozen_string_literal: true

module Views
  module JournalPromptTemplates
    class FormDialog < ::Views::Base
      def initialize(template:)
        @template = template
      end

      def view_template
        Dialog(open: true, id: "template_dialog") do
          DialogContent do
            DialogHeader do
              DialogTitle { @template.new_record? ? "New Prompt" : "Edit Prompt" }
            end

            render RubyUI::Form.new(
              action: @template.new_record? ? view_context.journal_prompt_templates_path : view_context.journal_prompt_template_path(@template),
              method: "post",
              class: "space-y-6",
              data: {
                controller: "modal-form template-schedule",
                modal_form_loading_message_value: @template.new_record? ? "Creating prompt..." : "Updating prompt...",
                turbo: true
              }
            ) do
              render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
              render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch") unless @template.new_record?

              div(id: "template_form_errors", class: "mb-4")

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Prompt Text" }
                render RubyUI::Textarea.new(
                  name: "journal_prompt_template[prompt_text]",
                  required: true,
                  autofocus: true,
                  rows: 4,
                  placeholder: "What did you learn today?"
                ) { @template.prompt_text }
              end

              div(class: "mb-4") do
                render RubyUI::Input.new(type: :hidden, name: "journal_prompt_template[active]", value: "0")
                label(class: "flex items-center gap-2") do
                  render RubyUI::Checkbox.new(
                    name: "journal_prompt_template[active]",
                    value: "1",
                    checked: @template.active?
                  )
                  span(class: "text-sm font-medium") { "Active" }
                end
              end

              # Schedule Configuration
              div(class: "mb-4") do
                render RubyUI::FormField.new do
                  render RubyUI::FormFieldLabel.new { "Schedule" }
                  select(
                    name: "journal_prompt_template[schedule_rule][frequency]",
                    data: { action: "change->template-schedule#updateFields" },
                    class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                  ) do
                    current_frequency = @template.schedule_rule&.dig("frequency")
                    option(value: "", selected: current_frequency.blank?) { "Manual (no schedule)" }
                    option(value: "daily", selected: current_frequency == "daily") { "Every day" }
                    option(value: "weekly_start", selected: current_frequency == "weekly_start") { "Beginning of week" }
                    option(value: "weekly_end", selected: current_frequency == "weekly_end") { "End of week" }
                    option(value: "monthly_start", selected: current_frequency == "monthly_start") { "First day of each month" }
                    option(value: "monthly_end", selected: current_frequency == "monthly_end") { "Last day of each month" }
                    option(value: "day_of_month", selected: current_frequency == "day_of_month") { "Specific day of month" }
                    option(value: "specific_weekdays", selected: current_frequency == "specific_weekdays") { "Specific days of week" }
                  end
                end
              end

              # Day of month field (conditional)
              div(
                class: "mb-4 #{"hidden" unless @template.schedule_rule&.dig("frequency") == "day_of_month"}",
                data: { template_schedule_target: "dayOfMonthField" }
              ) do
                render RubyUI::FormField.new do
                  render RubyUI::FormFieldLabel.new { "Day of Month (1-31)" }
                  render RubyUI::Input.new(
                    type: :number,
                    name: "journal_prompt_template[schedule_rule][day_of_month]",
                    min: 1,
                    max: 31,
                    value: @template.schedule_rule&.dig("day_of_month"),
                    placeholder: "1"
                  )
                end
              end

              # Weekdays checkboxes (conditional)
              div(
                class: "mb-4 #{"hidden" unless @template.schedule_rule&.dig("frequency") == "specific_weekdays"}",
                data: { template_schedule_target: "weekdaysField" }
              ) do
                render RubyUI::FormFieldLabel.new { "Days of Week" }
                div(class: "grid grid-cols-2 gap-2 mt-2") do
                  selected_days = @template.schedule_rule&.dig("days_of_week") || []
                  [
                    [ 0, "Sunday" ],
                    [ 1, "Monday" ],
                    [ 2, "Tuesday" ],
                    [ 3, "Wednesday" ],
                    [ 4, "Thursday" ],
                    [ 5, "Friday" ],
                    [ 6, "Saturday" ]
                  ].each do |day_num, day_name|
                    label(class: "flex items-center gap-2") do
                      render RubyUI::Checkbox.new(
                        name: "journal_prompt_template[schedule_rule][days_of_week][]",
                        value: day_num,
                        checked: selected_days.include?(day_num)
                      )
                      span(class: "text-sm") { day_name }
                    end
                  end
                end
              end

              div(class: "flex gap-2 justify-end") do
                Button(variant: :outline, type: :button, data: { action: "click->modal-form#cancelDialog" }) { "Cancel" }
                Button(variant: :primary, type: :submit) { @template.new_record? ? "Create Prompt" : "Update Prompt" }
              end
            end
          end
        end
      end
    end
  end
end
