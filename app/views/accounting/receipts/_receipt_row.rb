module Views
  module Accounting
    module Receipts
      class ReceiptRow < Views::Base
        def initialize(receipt:)
          @receipt = receipt
        end

        def view_template
          div(
            id: "receipt_#{@receipt.id}_div", 
            class: "flex flex-col w-full gap-2 rounded-md p-3 text-left transition-colors border border-border bg-muted hover:bg-muted/50"
          ) do
            div(class: "flex flex-row items-center justify-between gap-2") do
              div(class: "text-lg font-semibold mt-1") { @receipt.reference }
              div(class: "text-sm text-muted-foreground mt-1") { @receipt.invoice&.display_number }
            end
            div(class: "flex flex-row items-center justify-between w-full gap-2") do
              div(class: "flex flex-row items-center gap-2") do
                render Components::Icon.new(name: :created_date, size: "12", class: "w-5 h-5")
                div(class: "text-sm") { @receipt.issue_date.strftime("%d/%m/%Y") }
              end
              div(class: "flex flex-row items-center gap-2") do
                render Components::Icon.new(name: :payment_date, size: "12", class: "w-5 h-5")
                div(class: "text-sm") { @receipt.payment_date.strftime("%d/%m/%Y") }
              end
            end
            div(class: "flex flex-row items-start gap-2") do
              render_items_table
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