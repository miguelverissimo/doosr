module Views
  module Accounting
    module Invoices
      class ListContent < Views::Base
        def initialize(user:, **attrs)
          @user = user
          @invoices = user.invoices.order(year: :desc, number: :desc)
          super(**attrs)
        end

        def view_template
          if @invoices.empty?
            div(class: "flex h-full flex-col items-center justify-center") do
              p(class: "text-sm text-gray-500") { "No invoices found" }
            end
          else
            @invoices.each do |invoice|
              div(id: "invoice_#{invoice.id}_div", class: "mt-2") do
                render Views::Accounting::Invoices::InvoiceRow.new(invoice: invoice)
              end
            end
          end
        end
      end
    end
  end
end