module Views
  module Accounting
    module Receipts
      class ReceiptRow < ::Views::Base
        def initialize(receipt:)
          @receipt = receipt
        end

        def view_template
          div(
            id: "receipt_#{@receipt.id}_div",
            class: "flex flex-col w-full gap-2 rounded-md p-3 text-left transition-colors border border-border bg-muted hover:bg-muted/50 mt-2"
          ) do
            div(class: "flex flex-row items-center justify-between gap-2") do
              div(class: "text-lg font-semibold mt-1") { @receipt.reference }
              div(class: "text-sm text-muted-foreground mt-1") { @receipt.invoice&.display_number }
            end
            div(class: "flex flex-row items-center justify-between w-full gap-2") do
              div(class: "flex flex-row items-center gap-2") do
                render ::Components::Icon.new(name: :created_date, size: "12", class: "w-5 h-5")
                div(class: "text-sm") { @receipt.issue_date.strftime("%d/%m/%Y") }
              end
              div(class: "flex flex-row items-center gap-2") do
                render ::Components::Icon.new(name: :payment_date, size: "12", class: "w-5 h-5")
                div(class: "text-sm") { @receipt.payment_date.strftime("%d/%m/%Y") }
              end
            end
            div(class: "flex flex-row items-start gap-2") do
              render_items_table
            end
            div(class: "flex flex-row items-center justify-between gap-2") do
              render_payment_type_badge
              render_buttons
            end
          end
        end

        def render_payment_type_badge
          variant = ""
          text = ""
          case @receipt.payment_type
          when "total"
            variant = :lime
            text = "Total Payment"
          when "partial"
            variant = :amber
            text = "Partial Payment"
            text += " (completes payment)" if @receipt.completes_payment
          end

          render RubyUI::Badge.new(variant: variant, size: :md) { text }
        end

        def render_buttons
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
              render RubyUI::DialogTitle.new { "Edit Receipt" }
              render RubyUI::DialogDescription.new { "Update the receipt information" }
            end

            render RubyUI::DialogMiddle.new do
              render ::Components::Accounting::Receipts::Form.new(receipt: @receipt)
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
                render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete #{@receipt.reference}?" }
                render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the receipt." }
              end

              render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                render RubyUI::AlertDialogCancel.new { "Cancel" }

                form(
                  action: view_context.receipt_path(@receipt),
                  method: "post",
                  data: {
                    turbo_method: :delete,
                    action: "submit@document->ruby-ui--alert-dialog#dismiss"
                  },
                  class: "inline",
                  id: "delete_receipt_#{@receipt.id}"
                ) do
                  input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                  input(type: :hidden, name: "_method", value: "delete")
                  render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                end
              end
            end
          end
        end

        def render_items_table
          Table do
            TableHeader do
              TableRow do
                TableHead { "Item" }
                TableHead { "Quantity" }
                TableHead { "Unit Price" }
                TableHead { "Tax" }
                TableHead { "Total" }
              end
            end
            TableBody do
              @receipt.items.each do |item|
                TableRow do
                  TableCell { item.receipt_item.description }
                  TableCell { item.quantity }
                  TableCell { item.gross_value_formatted_without_currency }
                  TableCell { item.tax_percentage }
                  TableCell { item.value_with_tax_formatted_without_currency }
                end
              end
            end
            TableFooter do
              TableRow do
                TableHead(class: "font-medium", colspan: 4) { "Total" }
                TableHead(class: "font-medium text-right") { total_value_with_tax_formatted }
              end
            end
          end
        end

        private

        def total_value_with_tax_formatted
          total_cents = @receipt.items.sum(&:value_with_tax) || 0
          return "0.00" if total_cents == 0

          amount = BigDecimal(total_cents.to_s) / 100
          MoneyPresentable.format_currency_without_currency(amount)
        end
      end
    end
  end
end
