# frozen_string_literal: true

module Views
  module JournalPromptTemplates
    class TemplateRow < ::Views::Base
      def initialize(template:)
        @template = template
      end

      def view_template
        div(
          id: "template_#{@template.id}",
          class: "p-4 bg-card border rounded-lg"
        ) do
          div(class: "flex items-start justify-between gap-4") do
            div(class: "flex-1 min-w-0") do
              div(class: "flex items-center gap-2 mb-1") do
                p(class: "font-medium") { @template.prompt_text }
                unless @template.active?
                  span(class: "px-2 py-0.5 text-xs bg-muted text-muted-foreground rounded") { "Inactive" }
                end
              end

              if @template.schedule_rule.present? && @template.schedule_rule["frequency"].present?
                p(class: "text-sm text-muted-foreground") do
                  "Schedule: #{format_schedule(@template.schedule_rule)}"
                end
              else
                p(class: "text-sm text-muted-foreground") { "No schedule set" }
              end
            end

            div(class: "flex gap-2") do
              Button(
                variant: :secondary,
                size: :sm,
                icon: true,
                data: {
                  controller: "journal-template",
                  journal_template_url_value: view_context.edit_journal_prompt_template_path(@template),
                  action: "click->journal-template#openDialog"
                }
              ) do
                render ::Components::Icon::Edit.new(size: "12")
              end

              render RubyUI::AlertDialog.new do
                render RubyUI::AlertDialogTrigger.new do
                  Button(variant: :destructive, size: :sm, icon: true) do
                    render ::Components::Icon::Delete.new(size: "12")
                  end
                end

                render RubyUI::AlertDialogContent.new do
                  render RubyUI::AlertDialogHeader.new do
                    render RubyUI::AlertDialogTitle.new { "Delete this prompt template?" }
                    render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the prompt template." }
                  end

                  render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                    render RubyUI::AlertDialogCancel.new { "Cancel" }

                    form(
                      action: view_context.journal_prompt_template_path(@template),
                      method: "post",
                      data: { turbo_stream: true, action: "submit@document->ruby-ui--alert-dialog#dismiss" },
                      class: "inline"
                    ) do
                      csrf_token_field
                      render RubyUI::Input.new(type: :hidden, name: "_method", value: "delete")
                      render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                    end
                  end
                end
              end
            end
          end
        end
      end

      private

      def format_schedule(rule)
        case rule["frequency"]
        when "daily"
          "Every day"
        when "weekly_start"
          "Beginning of week"
        when "weekly_end"
          "End of week"
        when "monthly_start"
          "First day of each month"
        when "monthly_end"
          "Last day of each month"
        when "day_of_month"
          "Day #{rule['day_of_month']} of each month"
        when "every_n_days"
          "Every #{rule['interval']} days"
        when "specific_weekdays"
          days = rule["days_of_week"].map { |d| Date::DAYNAMES[d] }.join(", ")
          "Every #{days}"
        else
          "Custom"
        end
      end
    end
  end
end
