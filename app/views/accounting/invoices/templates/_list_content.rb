module Views
  module Accounting
    module Invoices
      module Templates
        class ListContent < Views::Base
          def initialize(user:, **attrs)
            @user = user
            @invoice_templates = user.invoice_templates.includes(:invoice_template_items)
            super(**attrs)
          end

          def view_template
            if @invoice_templates.empty?
              div(class: "flex h-full flex-col items-center justify-center") do
                p(class: "text-sm text-gray-500") { "No invoice templates found" }
              end
            else
              @invoice_templates.each do |invoice_template|
                div(id: "invoice_template_#{invoice_template.id}_div", class: "mt-2") do
                  render Views::Accounting::Invoices::Templates::InvoiceTemplateRow.new(invoice_template: invoice_template)
                end
              end
            end
          end
        end
      end
    end
  end
end