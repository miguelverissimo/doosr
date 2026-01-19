# frozen_string_literal: true

module Views
  module Banking
    class CsvImportDialog < ::Views::Base
      def view_template
        div(id: "csv_import_dialog") do
          render RubyUI::Dialog.new(open: true) do
            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Import CSV" }
                render RubyUI::DialogDescription.new { "Upload a CSV file to import bank transactions" }
              end

              render RubyUI::DialogMiddle.new do
                render_form
              end
            end
          end
        end
      end

      private

      def render_form
        form(
          action: view_context.import_csv_banking_index_path,
          method: "post",
          enctype: "multipart/form-data",
          data: {
            controller: "modal-form",
            modal_form_loading_message_value: "Importing CSV...",
            modal_form_success_message_value: "CSV import started. You'll be notified when complete.",
            turbo: true
          },
          class: "space-y-4"
        ) do
          csrf_token_field

          div(id: "csv_import_form_errors", class: "text-sm text-destructive")

          render_file_field
          render_format_hint

          render_actions
        end
      end

      def csrf_token_field
        render RubyUI::Input.new(
          type: :hidden,
          name: "authenticity_token",
          value: view_context.form_authenticity_token
        )
      end

      def render_file_field
        render RubyUI::FormField.new do
          render RubyUI::FormFieldLabel.new(for: "csv_file") { "CSV File" }
          render RubyUI::Input.new(
            type: :file,
            id: "csv_file",
            name: "csv_file",
            accept: ".csv",
            required: true,
            class: "file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-primary file:text-primary-foreground hover:file:bg-primary/90 cursor-pointer"
          )
          render RubyUI::FormFieldError.new
        end
      end

      def render_format_hint
        div(class: "rounded-md border border-border bg-muted/50 p-4") do
          h4(class: "text-sm font-medium mb-2") { "Expected CSV Format" }
          p(class: "text-xs text-muted-foreground mb-2") do
            plain "Your CSV file should have the following columns:"
          end
          div(class: "font-mono text-xs bg-background p-2 rounded border") do
            plain "Date,Description,Value"
          end
          ul(class: "text-xs text-muted-foreground mt-2 space-y-1 list-disc list-inside") do
            li { "Date: DD-MM-YYYY format (e.g., 15-01-2026)" }
            li { "Description: Transaction description text" }
            li { "Value: Amount with negative for expenses (e.g., -24.50 or 1500.00)" }
          end
        end
      end

      def render_actions
        div(class: "flex gap-2 justify-end mt-6") do
          Button(variant: :outline, type: "button", data: { action: "click->modal-form#cancelDialog" }) { "Cancel" }
          Button(variant: :primary, type: "submit") do
            render ::Components::Icon::Add.new(size: "16", class: "mr-2")
            plain "Import CSV"
          end
        end
      end
    end
  end
end
