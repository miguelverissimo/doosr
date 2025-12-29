module Views
  module Accounting
    module Invoices
      class ReceiptsList < ::Views::Base
        def initialize(invoice:)
          @invoice = invoice
          @receipts = invoice.receipts
            .includes(:items)
            .includes(:receipt_items)
            .order(issue_date: :desc)
        end

        def view_template
          if @receipts.empty?
            div(class: "flex h-full flex-col items-center justify-center py-8") do
              p(class: "text-sm text-muted-foreground") { "No receipts found for this invoice" }
            end
          else
            div(class: "space-y-4") do
              @receipts.each do |receipt|
                div(id: "receipt_#{receipt.id}_div", class: "mt-2") do
                  render ::Views::Accounting::Receipts::ReceiptRow.new(receipt: receipt)
                end
              end
            end
          end
        end
      end
    end
  end
end
