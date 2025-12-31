module Views
  module Accounting
    module Invoices
      module Templates
        class FormDialog < ::Views::Base
          def initialize(invoice_template:, user:)
            @invoice_template = invoice_template
            @user = user
          end

          def view_template
            turbo_frame_tag "invoice_template_dialog" do
              render RubyUI::Dialog.new(open: true) do
                render RubyUI::DialogContent.new(size: :lg) do
                  render RubyUI::DialogHeader.new do
                    render RubyUI::DialogDescription.new { "Manage invoice template" }
                  end

                  render RubyUI::DialogMiddle.new do
                    render ::Components::Accounting::Invoices::Templates::Form.new(invoice_template: @invoice_template, user: @user)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
