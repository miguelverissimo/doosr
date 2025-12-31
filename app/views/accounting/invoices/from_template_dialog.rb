module Views
  module Accounting
    module Invoices
      class FromTemplateDialog < ::Views::Base
        def initialize(user:)
          @user = user
        end

        def view_template
          turbo_frame_tag "invoice_dialog" do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Create Invoice from Template" }
                  render RubyUI::DialogDescription.new { "Select a template to create an invoice" }
                end

                render RubyUI::DialogMiddle.new do
                  render ::Components::Accounting::Invoices::FromTemplateForm.new(user: @user)
                end
              end
            end
          end
        end
      end
    end
  end
end
