module Views
  module Accounting
    module AccountingItems
      class AccountingItemRow < ::Views::Base
        include Phlex::Rails::Helpers::NumberToCurrency

        def initialize(accounting_item:)
          @accounting_item = accounting_item
        end

        def view_template
          div(
            id: "accounting_item_#{@accounting_item.id}_div",
            class: "flex flex-col w-full gap-2 rounded-md p-3 text-left transition-colors border border-border bg-muted hover:bg-muted/50"
          ) do
            div(class: "flex flex-row items-center justify-between gap-2") do
              div(class: "text-md font-bold mt-1") { @accounting_item.name }
              div(class: "text-sm mt-1") { @accounting_item.reference }
            end

            div(class: "flex flex-row items-center justify-between gap-2") do
              render_monetary_info(@accounting_item)
            end
            div(class: "flex flex-row items-center justify-between gap-2") do
              div(class: "flex gap-2 justify-start") do
                render_badge(@accounting_item)

                div(class: "flex flex-row items-center gap-2") do
                  if @accounting_item.convert_currency
                    span(class: "text-lime-500") { render ::Components::Icon.new(name: :convert_currency, size: "12", class: "w-5 h-5") }
                  else
                    span(class: "text-red-500") { render ::Components::Icon.new(name: :no_currency_conversion, size: "12", class: "w-5 h-5") }
                  end
                end
              end

              div(class: "flex gap-2 justify-end") do
                render RubyUI::Dialog.new do
                  render RubyUI::DialogTrigger.new do
                    Button(variant: :outline, icon: true) do
                      render ::Components::Icon.new(name: :edit, size: "12", class: "w-5 h-5")
                    end
                  end
                  render_edit_dialog
                end

                render_delete_confirmation_dialog
              end
            end
          end
        end

        def render_edit_dialog
          render RubyUI::DialogContent.new(size: :lg) do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogTitle.new { "Edit Accounting Item" }
              render RubyUI::DialogDescription.new { "Update the accounting item information" }
            end

            render RubyUI::DialogMiddle.new do
              render ::Components::Accounting::AccountingItems::Form.new(accounting_item: @accounting_item)
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
                render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete #{@accounting_item.name}?" }
                render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the accounting item." }
              end

              # Footer actions: single horizontal row, right aligned
              render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                render RubyUI::AlertDialogCancel.new { "Cancel" }

                # Form for delete action
                form(
                  action: view_context.accounting_item_path(@accounting_item),
                  method: "post",
                  data: {
                    turbo_method: :delete,
                    action: "submit@document->ruby-ui--alert-dialog#dismiss"
                  },
                  class: "inline",
                  id: "delete_accounting_item_#{@accounting_item.id}"
                ) do
                  input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                  input(type: :hidden, name: "_method", value: "delete")
                  render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                end
              end
            end
          end
        end

        def render_monetary_info(accounting_item)
          div(class: "text-md mt-1") do
            plain "#{accounting_item.currency} "
            plain number_to_currency(accounting_item.price / 100.0)
            plain " / #{accounting_item.unit} "
            span(class: "text-sm") do
              plain "that "
              if accounting_item.convert_currency
                span(class: "font-bold text-lime-500") { "will" }
              else
                span(class: "font-bold text-red-500") { "will not" }
              end
              plain " be converted to the invoice currency on issuance."
            end
          end
        end

        def render_badge(accounting_item)
          case accounting_item.kind
          when "service"
            Badge(variant: :lime) { "Service" }
          when "product"
            Badge(variant: :amber) { "Product" }
          when "tool"
            Badge(variant: :teal) { "Tool" }
          when "goods"
            Badge(variant: :purple) { "Goods" }
          when "equipment"
            Badge(variant: :indigo) { "Equipment" }
          when "other"
            Badge(variant: :rose) { "Other" }
          end
        end
      end
    end
  end
end
