module Views
  module Accounting
    module Settings
      class Index < ::Views::Base
        def initialize(user:)
          @user = user
        end

        def view_template
          turbo_frame_tag "settings_tab_content" do
            div(class: "flex h-full flex-col") do
              h1(class: "text-xl font-bold") { "Settings" }

            # Tax Brackets
            div(class: "rounded-lg border p-4 md:p-6 space-y-4 bg-background text-foreground mt-4") do
              render RubyUI::Dialog.new do
                div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2") do
                  render RubyUI::DialogTitle.new { "Tax Brackets" }
                  render RubyUI::DialogTrigger.new do
                    Button(variant: :primary, size: :sm, class: "w-full sm:w-auto") { "Add Tax Bracket" }
                  end
                end
                div(id: "tax_brackets_list") do
                  render ::Views::Accounting::Settings::TaxBrackets::ListContent.new(user: @user)
                end
                render_tax_bracket_form_dialog
              end
            end

            # User Addresses
            div(class: "rounded-lg border p-4 md:p-6 space-y-4 bg-background text-foreground mt-4") do
              render RubyUI::Dialog.new do
                div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2") do
                  render RubyUI::DialogTitle.new { "Your Addresses" }
                  render RubyUI::DialogTrigger.new do
                    Button(variant: :primary, size: :sm, class: "w-full sm:w-auto") { "Add Address" }
                  end
                end
                div(id: "user_addresses_list") do
                  render ::Views::Accounting::Settings::UserAddresses::ListContent.new(user: @user)
                end
                render_address_form_dialog
              end
            end

            # Accounting Logos
            div(class: "rounded-lg border p-4 md:p-6 space-y-4 bg-background text-foreground mt-4") do
              render RubyUI::Dialog.new do
                div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2") do
                  render RubyUI::DialogTitle.new { "Your Logos" }
                  render RubyUI::DialogTrigger.new do
                    Button(variant: :primary, size: :sm, class: "w-full sm:w-auto") { "Add Logo" }
                  end
                end
                div(id: "logos_list") do
                  render ::Views::Accounting::Settings::Logos::ListContents.new(user: @user)
                end
                render_logo_form_dialog
              end
            end

            # Bank Infos
            div(class: "rounded-lg border p-4 md:p-6 space-y-4 bg-background text-foreground mt-4") do
              render RubyUI::Dialog.new do
                div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2") do
                  render RubyUI::DialogTitle.new { "Your Bank Infos" }
                  render RubyUI::DialogTrigger.new do
                    Button(variant: :primary, size: :sm, class: "w-full sm:w-auto") { "Add Bank Info" }
                  end
                end
                div(id: "bank_infos_list") do
                  render ::Views::Accounting::Settings::BankInfos::ListContent.new(user: @user)
                end
                render_bank_info_form_dialog
              end
            end
          end
        end
        end

        def render_tax_bracket_form_dialog(tax_bracket: nil)
          render RubyUI::DialogContent.new(size: :md) do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogDescription.new { "Manage tax bracket" }
            end

            render RubyUI::DialogMiddle.new do
              render ::Components::Accounting::Settings::TaxBrackets::Form.new(tax_bracket: tax_bracket)
            end
          end
        end

        def render_address_form_dialog(address: nil)
          render RubyUI::DialogContent.new(size: :md) do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogDescription.new { "Manage address" }
            end

            render RubyUI::DialogMiddle.new do
              render ::Components::Accounting::Settings::Addresses::Form.new(address: address)
            end
          end
        end

        def render_logo_form_dialog(accounting_logo: nil)
          render RubyUI::DialogContent.new(size: :md) do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogDescription.new { "Manage logo" }
            end

            render RubyUI::DialogMiddle.new do
              render ::Components::Accounting::Settings::Logos::Form.new(accounting_logo: accounting_logo)
            end
          end
        end

        def render_bank_info_form_dialog(bank_info: nil)
          render RubyUI::DialogContent.new(size: :md) do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogDescription.new { "Manage bank info" }
            end

            render RubyUI::DialogMiddle.new do
              render ::Components::Accounting::Settings::BankInfos::Form.new(bank_info: bank_info)
            end
          end
        end
      end
    end
  end
end
