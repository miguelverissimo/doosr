module Views
  module Accounting
    module Receipts
      module ReceiptItems
        class ReceiptItemRow < ::Views::Base
          def initialize(receipt_item:)
            @receipt_item = receipt_item
          end

          def view_template
            div(
              id: "receipt_item_#{@receipt_item.id}_div",
              class: "flex flex-col w-full gap-2 rounded-md p-3 text-left transition-colors border border-border bg-muted hover:bg-muted/50 mt-2"
            ) do
              div(class: "flex flex-row items-center justify-between gap-2") do
                div(class: "text-md font-semibold mt-1") { @receipt_item.description }
                render_actions
              end

              div(class: "flex flex-row items-center justify-between gap-2") do
                div(class: "text-sm text-muted-foreground mt-1") { @receipt_item.reference }
                render_badge
              end

              render_monetary_info
            end
          end

          def render_actions
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

          def render_edit_dialog
            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Edit Receipt Item" }
                render RubyUI::DialogDescription.new { "Update the receipt item information" }
              end

              render RubyUI::DialogMiddle.new do
                render ::Components::Accounting::Receipts::ReceiptItemForm.new(receipt_item: @receipt_item)
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
                  render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete #{@receipt_item.description}?" }
                  render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the receipt item." }
                end
                
                # Footer actions: single horizontal row, right aligned
                render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                  render RubyUI::AlertDialogCancel.new { "Cancel" }

                  # Form for delete action
                  form(
                    action: view_context.receipt_item_path(@receipt_item),
                    method: "post",
                    data: { 
                      turbo_method: :delete,
                      action: "submit@document->ruby-ui--alert-dialog#dismiss"
                    },
                    class: "inline",
                    id: "delete_receipt_item_#{@receipt_item.id}"
                  ) do
                    input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                    input(type: :hidden, name: "_method", value: "delete")
                    render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                  end
                end
              end
            end
          end

          def render_badge
            case @receipt_item.kind
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

          def render_monetary_info
            div(class: "flex flex-col items-start justify-between gap-2 text-sm") do
              div do
                span(class: "font-bold text-muted-foreground") { "Gross Unit Price: " }
                plain @receipt_item.gross_unit_price_formatted
                plain " / #{@receipt_item.unit}"
              end
              div do
                span(class: "font-bold text-muted-foreground") { "Tax: " }
                plain "#{@receipt_item.tax_bracket.percentage}%"
                span(class: "text-muted-foreground") { " - #{@receipt_item.exemption_motive}" } if @receipt_item.exemption_motive.present?
              end
              div(class: "text-md") do
                span(class: "font-bold text-muted-foreground") { "Unit Price with Tax: " }
                plain @receipt_item.unit_price_with_tax_formatted
                plain " / #{@receipt_item.unit}"
              end
            end
          end
        end
      end
    end
  end
end