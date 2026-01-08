# frozen_string_literal: true

module Views
  module Journals
    class FormDialog < ::Views::Base
      def initialize(journal:)
        @journal = journal
      end

      def view_template
        Dialog(open: true, id: "journal_dialog") do
          DialogContent do
            DialogHeader do
              DialogTitle { "New Journal Entry" }
            end

            render RubyUI::Form.new(
              action: view_context.journals_path,
              method: "post",
              class: "space-y-6",
              data: {
                controller: "modal-form",
                modal_form_loading_message_value: "Creating journal...",
                turbo: true
              }
            ) do
              render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)

              div(id: "journal_form_errors", class: "mb-4")

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Date" }
                render RubyUI::Input.new(
                  type: :date,
                  name: "journal[date]",
                  value: @journal.date&.to_s,
                  required: true,
                  class: "date-input-icon-light-dark"
                )
                p(class: "text-xs text-muted-foreground mt-1") { "Select a date for your journal entry" }
                render RubyUI::FormFieldError.new
              end

              div(class: "flex gap-2 justify-end") do
                Button(
                  variant: :outline,
                  type: :button,
                  data: { action: "click->modal-form#cancelDialog" }
                ) { "Cancel" }
                Button(variant: :primary, type: :submit) { "Create Journal" }
              end
            end
          end
        end
      end
    end
  end
end
