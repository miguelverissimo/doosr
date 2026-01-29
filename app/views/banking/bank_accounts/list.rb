# frozen_string_literal: true

module Views
  module Banking
    module BankAccounts
      class List < ::Views::Base
        include RubyUI

        ACCOUNT_TYPE_LABELS = {
          "checking" => "Checking",
          "savings" => "Savings",
          "credit_card" => "Credit Card",
          "investment" => "Investment",
          "other" => "Other"
        }.freeze

        def initialize(bank_accounts:)
          @bank_accounts = bank_accounts
        end

        def view_template
          div(id: "bank_accounts_content", class: "space-y-4") do
            render_add_button
            render_accounts_list
          end
        end

        private

        def render_add_button
          div(class: "flex justify-end mb-4") do
            button(
              type: "button",
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2",
              data: {
                controller: "turbo-fetch",
                turbo_fetch_url_value: view_context.new_banking_bank_account_path,
                action: "click->turbo-fetch#load"
              }
            ) do
              render ::Components::Icon::Add.new(size: "16", class: "mr-2")
              plain "Add Account"
            end
          end
        end

        def render_accounts_list
          if @bank_accounts.empty?
            div(class: "text-center py-8 text-muted-foreground") do
              plain "No bank accounts yet. Click Add Account to create one."
            end
          else
            div(class: "divide-y divide-border rounded-md border") do
              @bank_accounts.each do |account|
                render_account_row(account)
              end
            end
          end
        end

        def render_account_row(account)
          div(
            id: "bank_account_#{account.id}",
            class: "flex items-center justify-between p-3 hover:bg-muted/50"
          ) do
            div(class: "flex items-center gap-3 flex-1 min-w-0") do
              render_account_badge(account)
              div do
                div(class: "flex items-center gap-2 mb-1") do
                  span(class: "font-medium") { account.name }
                  render_account_type_badge(account.account_type)
                  render_status_badge(account.active)
                end
                render_transaction_count(account)
              end
            end
            div(class: "flex items-center gap-1 ml-2 shrink-0") do
              render_edit_button(account)
              render_delete_button(account)
            end
          end
        end

        def render_account_badge(account)
          div(
            class: "inline-flex items-center justify-center w-8 h-8 rounded-full text-sm font-bold shrink-0",
            style: "background-color: #{account.bg_color}; color: #{account.fg_color};"
          ) do
            plain account.display_letter
          end
        end

        def render_account_type_badge(account_type)
          div(class: "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-secondary text-secondary-foreground") do
            span { ACCOUNT_TYPE_LABELS[account_type] || account_type.titleize }
          end
        end

        def render_status_badge(active)
          return if active

          div(class: "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-muted text-muted-foreground") do
            span { "Inactive" }
          end
        end

        def render_transaction_count(account)
          count = account.transactions_count
          span(class: "text-xs text-muted-foreground") do
            plain "#{count} transaction#{'s' if count != 1}"
          end
        end

        def render_edit_button(account)
          button(
            type: "button",
            class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 hover:bg-accent hover:text-accent-foreground h-8 w-8",
            data: {
              controller: "turbo-fetch",
              turbo_fetch_url_value: view_context.edit_banking_bank_account_path(account),
              action: "click->turbo-fetch#load"
            }
          ) do
            render ::Components::Icon::Edit.new(size: "16")
          end
        end

        def render_delete_button(account)
          render AlertDialog.new do
            render AlertDialogTrigger.new do
              button(
                type: "button",
                class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 hover:bg-accent hover:text-accent-foreground h-8 w-8"
              ) do
                render ::Components::Icon::Trash.new(size: "16")
              end
            end

            render AlertDialogContent.new do
              render AlertDialogHeader.new do
                render AlertDialogTitle.new { "Delete account \"#{account.name}\"?" }
                render AlertDialogDescription.new do
                  if account.transactions_count > 0
                    plain "This account has #{account.transactions_count} transactions. The transactions will be kept but will no longer be associated with this account."
                  else
                    plain "This will permanently delete the bank account."
                  end
                end
              end

              render AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                render AlertDialogCancel.new { "Cancel" }

                render RubyUI::Form.new(
                  action: view_context.banking_bank_account_path(account),
                  method: "post",
                  data: {
                    controller: "form-loading",
                    form_loading_message_value: "Deleting account...",
                    turbo_stream: true,
                    action: "submit@document->ruby-ui--alert-dialog#dismiss"
                  },
                  class: "inline"
                ) do
                  render RubyUI::Input.new(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                  render RubyUI::Input.new(type: :hidden, name: "_method", value: "delete")
                  render AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                end
              end
            end
          end
        end
      end
    end
  end
end
