# frozen_string_literal: true

module Views
  module JournalPrompts
    class FormDialog < ::Views::Base
      def initialize(prompt:, journal:, templates:)
        @prompt = prompt
        @journal = journal
        @templates = templates
      end

      def view_template
        Dialog(open: true, id: "prompt_dialog") do
          DialogContent do
            DialogHeader do
              DialogTitle { "Add Prompt" }
            end

            render RubyUI::Form.new(
              action: view_context.journal_journal_prompts_path(@journal),
              method: "post",
              class: "space-y-6",
              data: {
                controller: "modal-form",
                modal_form_loading_message_value: "Adding prompt...",
                turbo: true
              }
            ) do
              render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)

              div(id: "prompt_form_errors", class: "mb-4")

              # Template selection (if templates exist)
              if @templates.any?
                div(class: "mb-4") do
                  label(class: "block text-sm font-medium mb-2") { "Choose from templates (optional)" }
                  div(class: "grid grid-cols-1 gap-2 mb-4") do
                    @templates.each do |template|
                      button(
                        type: "button",
                        class: "text-left px-3 py-2 border rounded-md hover:bg-accent transition-colors",
                        data: {
                          action: "click->modal-form#selectTemplate",
                          template_text: template.prompt_text
                        }
                      ) do
                        div(class: "font-medium text-sm") { template.name || template.prompt_text.truncate(50) }
                        div(class: "text-xs text-muted-foreground") { template.prompt_text.truncate(100) }
                      end
                    end
                  end
                end
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Prompt Text" }
                render RubyUI::Textarea.new(
                  name: "journal_prompt[prompt_text]",
                  required: true,
                  rows: 4,
                  placeholder: "What question or prompt would you like to reflect on?"
                ) do
                  @prompt.prompt_text
                end
                render RubyUI::FormFieldError.new
              end

              div(class: "flex gap-2 justify-end") do
                Button(
                  variant: :outline,
                  type: :button,
                  data: { action: "click->modal-form#cancelDialog" }
                ) { "Cancel" }
                Button(variant: :primary, type: :submit) { "Add Prompt" }
              end
            end
          end
        end
      end
    end
  end
end
