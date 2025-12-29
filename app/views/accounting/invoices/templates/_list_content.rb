module Views
  module Accounting
    module Invoices
      module Templates
        class ListContent < ::Views::Base
          def initialize(user:, **attrs)
            @user = user
            @invoice_templates = user.invoice_templates.includes(
              :invoice_template_items,
              :bank_info,
              :accounting_logo,
              :provider_address,
              customer: :address
            )
            super(**attrs)
          end

          def view_template
            turbo_frame_tag "invoice_templates_content" do
              if @invoice_templates.empty?
                div(class: "flex h-full flex-col items-center justify-center") do
                  p(class: "text-sm text-gray-500") { "No invoice templates found" }
                end
              else
                @invoice_templates.each do |invoice_template|
                  render ::Views::Accounting::Invoices::Templates::InvoiceTemplateRow.new(invoice_template: invoice_template)
                end
              end
            end
          end
        end
      end
    end
  end
end
