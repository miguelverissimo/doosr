module Views
  module Accounting
    module Settings
      module TaxBrackets
        class Row < ::Views::Base
          def initialize(tax_bracket:)
            @tax_bracket = tax_bracket
          end

          def view_template
            TableRow(id: view_context.dom_id(@tax_bracket, :row)) do
              TableCell do
                span(style: "font-size: 0.625rem; line-height: 1") { @tax_bracket.id }
              end
              TableCell { @tax_bracket.name }
              TableCell { @tax_bracket.percentage.to_s + "%" }
              TableCell { @tax_bracket.legal_reference.empty? ? "-" : @tax_bracket.legal_reference }
              TableCell do
                div(class: "flex gap-2 justify-end") do
                  # Edit button with dialog
                  render RubyUI::Dialog.new do
                    render RubyUI::DialogTrigger.new do
                      Button(variant: :outline, icon: true) do
                        render ::Components::Icon.new(name: :edit, size: "12", class: "w-5 h-5")
                      end
                    end

                    render_edit_dialog
                  end

                  # Delete button with AlertDialog confirmation
                  render_delete_confirmation_dialog
                end
              end
            end
          end

          def render_edit_dialog
            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Edit Tax Bracket" }
                render RubyUI::DialogDescription.new { "Update the tax bracket information" }
              end

              render RubyUI::DialogMiddle.new do
                render ::Components::Accounting::Settings::TaxBrackets::Form.new(tax_bracket: @tax_bracket)
              end
            end
          end

          def render_delete_confirmation_dialog
            render RubyUI::AlertDialog.new do
              render RubyUI::AlertDialogTrigger.new do
                Button(variant: :destructive, icon: true) do
                  render ::Components::Icon.new(name: :delete, size: "12", class: "w-5 h-5")
                end
              end

              render RubyUI::AlertDialogContent.new do
                render RubyUI::AlertDialogHeader.new do
                  render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete #{@tax_bracket.name}?" }
                  render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the tax bracket." }
                end

                # Footer actions: single horizontal row, right aligned
                render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                  render RubyUI::AlertDialogCancel.new { "Cancel" }

                  # Form for delete action
                  form(
                    action: view_context.settings_tax_bracket_path(@tax_bracket),
                    method: "post",
                    data: {
                      controller: "form-loading",
                      turbo_method: :delete,
                      action: "turbo:submit-end->ruby-ui--alert-dialog#dismiss turbo:submit-end->form-loading#handleResponse"
                    },
                    class: "inline",
                    id: "delete_tax_bracket_#{@tax_bracket.id}"
                  ) do
                    input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                    input(type: :hidden, name: "_method", value: "delete")
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
