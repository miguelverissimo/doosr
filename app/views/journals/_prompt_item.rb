# frozen_string_literal: true

module Views
  module Journals
    class PromptItem < ::Views::Base
      def initialize(prompt:)
        @prompt = prompt
      end

      def view_template
        div(
          id: "journal_prompt_#{@prompt.id}",
          class: "p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg"
        ) do
          div(class: "flex items-start gap-3") do
            render ::Components::Icon::Prompt.new(size: "16", class: "text-blue-600 dark:text-blue-400 mt-1")

            div(class: "flex-1") do
              p(class: "font-medium text-blue-900 dark:text-blue-100") { @prompt.prompt_text }

              div(class: "flex gap-2 mt-2") do
                Button(
                  variant: :tinted,
                  tint: :cyan,
                  size: :sm,
                  data: {
                    controller: "journal-prompt",
                    journal_prompt_journal_id_value: @prompt.journal_id,
                    journal_prompt_prompt_id_value: @prompt.id,
                    action: "click->journal-prompt#respondToPrompt"
                  }
                ) do
                  render ::Components::Icon::Respond.new(size: "12")
                  span(class: "ml-1") { "Respond" }
                end

                render RubyUI::AlertDialog.new do
                  render RubyUI::AlertDialogTrigger.new do
                    Button(variant: :destructive, size: :sm, icon: true) do
                      render ::Components::Icon::Delete.new(size: "12")
                    end
                  end

                  render RubyUI::AlertDialogContent.new do
                    render RubyUI::AlertDialogHeader.new do
                      render RubyUI::AlertDialogTitle.new { "Delete this prompt?" }
                      render RubyUI::AlertDialogDescription.new { "This action cannot be undone." }
                    end

                    render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                      render RubyUI::AlertDialogCancel.new { "Cancel" }

                      form(
                        action: view_context.journal_prompt_path(@prompt),
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
          end
        end
      end
    end
  end
end
