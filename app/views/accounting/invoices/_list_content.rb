module Views
  module Accounting
    module Invoices
      class ListContent < ::Views::Base
        def initialize(user:, filter: "unpaid", **attrs)
          @user = user
          @filter = filter

          # Filter invoices based on the filter parameter
          @invoices = case filter
          when "paid"
            user.invoices.where(state: :paid)
          when "all"
            user.invoices
          else # "unpaid" is default
            user.invoices.where.not(state: :paid)
          end

          @invoices = @invoices.includes(:invoice_items, :items, :receipts).order(year: :desc, number: :desc)

          # Query receipt items once for all forms
          @receipt_items = {
            manev_h: user.receipt_items.find_by(reference: "OUT - MANEV-H"),
            manev_on_call: user.receipt_items.find_by(reference: "OUT - MANEV-ON-CALL"),
            token: user.receipt_items.find_by(reference: "OUT - TOKEN")
          }

          # Query available invoices once for all forms
          @available_invoices = user.invoices
            .where(state: :paid)
            .where.not(id: ::Accounting::Receipt.where.not(invoice_id: nil).select(:invoice_id))
            .order(year: :desc, number: :desc)
            .to_a

          super(**attrs)
        end

        def view_template
          turbo_frame_tag "invoices_content" do
            if @invoices.empty?
              div(class: "flex h-full flex-col items-center justify-center") do
                p(class: "text-sm text-gray-500") { "No invoices found" }
              end
            else
              @invoices.each do |invoice|
                render ::Views::Accounting::Invoices::InvoiceRow.new(
                  invoice: invoice,
                  receipt_items: @receipt_items,
                  available_invoices: @available_invoices
                )
              end
            end
          end
        end
      end
    end
  end
end