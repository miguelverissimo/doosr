module Views
  module Accounting
    module Settings
      module BankInfos
        class BankInfoRow < ::Views::Base
          def initialize(bank_info:)
            @bank_info = bank_info
          end

          def view_template
            div(
              id: "bank_info_#{@bank_info.id}_div",
              class: "flex flex-col w-full cursor-pointer gap-2 rounded-md p-3 text-left bg-accent hover:bg-accent/50 transition-colors"
            ) do
              div(class: "flex flex-row items-center justify-between gap-2") do
                div(class: "text-lg font-bold mt-1") { @bank_info.name }
              end
              div(class: "flex flex-row items-start justify-between gap-2") do
                div(class: "flex flex-col gap-1") do
                  if @bank_info.is_eu?
                    div(class: "text-sm mt-1") do
                      span(class: "font-bold") { "IBAN: " }
                      plain(@bank_info.iban)
                    end
                    div(class: "text-sm mt-1") do
                      span(class: "font-bold") { "SWIFT/BIC: " }
                      plain(@bank_info.swift_bic)
                    end
                  else
                    div(class: "text-sm mt-1") do
                      span(class: "font-bold") { "Account Number: " }
                      plain(@bank_info.account_number)
                    end
                    div(class: "text-sm mt-1") do
                      span(class: "font-bold") { "Routing Number: " }
                      plain(@bank_info.routing_number)
                    end
                  end
                end
                div(class: "flex flex-row items-center justify-end gap-2") do
                  # Edit button with dialog
                  render RubyUI::Dialog.new do
                    render RubyUI::DialogTrigger.new do
                      Button(variant: :outline, icon: true) do
                        render ::Components::Icon.new(name: :edit, size: "12", class: "w-4 h-4")
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

          private

          def render_edit_dialog
            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Edit Bank Info" }
              end

              render RubyUI::DialogMiddle.new do
                render ::Components::Accounting::Settings::BankInfos::Form.new(bank_info: @bank_info)
              end
            end
          end

          def render_delete_confirmation_dialog
            render RubyUI::AlertDialog.new do
              render RubyUI::AlertDialogTrigger.new do
                Button(variant: :destructive, icon: true) do
                  render ::Components::Icon.new(name: :delete, size: "12", class: "w-4 h-4")
                end
              end

              render RubyUI::AlertDialogContent.new do
                render RubyUI::AlertDialogHeader.new do
                  render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete #{@bank_info.name}?" }
                  render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the bank info." }
                end

                render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                  render RubyUI::AlertDialogCancel.new { "Cancel" }

                  form(
                    action: view_context.settings_bank_info_path(@bank_info),
                    method: "post",
                    data: {
                      turbo_method: :delete,
                      action: "submit@document->ruby-ui--alert-dialog#dismiss"
                    },
                    class: "inline",
                    id: "delete_bank_info_#{@bank_info.id}"
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
