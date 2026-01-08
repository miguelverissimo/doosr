# frozen_string_literal: true

module Views
  module JournalFragments
    class FormDialog < ::Views::Base
      def initialize(fragment:, journal:, prompt: nil)
        @fragment = fragment
        @journal = journal
        @prompt = prompt
      end

      def view_template
        Dialog(open: true, id: "fragment_dialog") do
          DialogContent do
            DialogHeader do
              DialogTitle { @fragment.new_record? ? "New Journal Entry" : "Edit Journal Entry" }
            end

            render RubyUI::Form.new(
              action: @fragment.new_record? ? view_context.journal_journal_fragments_path(@journal, prompt_id: @prompt&.id) : view_context.journal_fragment_path(@fragment),
              method: "post",
              class: "space-y-6",
              data: {
                controller: "modal-form",
                modal_form_loading_message_value: @fragment.new_record? ? "Creating entry..." : "Updating entry...",
                turbo: true
              }
            ) do
              render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
              render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch") unless @fragment.new_record?

              div(id: "fragment_form_errors", class: "mb-4")

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Content (Markdown supported)" }
                render RubyUI::Textarea.new(
                  name: "journal_fragment[content]",
                  required: true,
                  rows: 10,
                  placeholder: "Write your journal entry here... Markdown is supported."
                ) do
                  @fragment.content
                end
                render RubyUI::FormFieldError.new
              end

              div(class: "flex gap-2 justify-end") do
                Button(
                  variant: :outline,
                  type: :button,
                  data: { action: "click->modal-form#cancelDialog" }
                ) { "Cancel" }
                Button(variant: :primary, type: :submit) { "Save Entry" }
              end
            end
          end
        end
      end
    end
  end
end
