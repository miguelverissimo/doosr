module Views
  module Accounting
    module Invoices
      class FormDialog < ::Views::Base
        def initialize(invoice:)
          @invoice = invoice
        end

        def view_template
          turbo_frame_tag "invoice_dialog" do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Add Invoice" }
                  render RubyUI::DialogDescription.new { "Create a new invoice" }
                end

                render RubyUI::DialogMiddle.new do
                  render ::Components::Accounting::Invoices::Form.new(invoice: @invoice)
                end
              end
            end
          end
        end
      end
    end
  end
end
