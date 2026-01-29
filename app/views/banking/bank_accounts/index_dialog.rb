# frozen_string_literal: true

module Views
  module Banking
    module BankAccounts
      class IndexDialog < ::Views::Base
        def initialize(bank_accounts:)
          @bank_accounts = bank_accounts
        end

        def view_template
          div(id: "bank_accounts_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Manage Bank Accounts" }
                  render RubyUI::DialogDescription.new do
                    plain "Add and manage bank accounts to organize your transactions"
                  end
                end

                render RubyUI::DialogMiddle.new do
                  render List.new(bank_accounts: @bank_accounts)
                end
              end
            end
          end
        end
      end
    end
  end
end
