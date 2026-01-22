# frozen_string_literal: true

module Views
  module Banking
    module PaymentReminders
      class IndexDialog < ::Views::Base
        def initialize(payment_reminders:)
          @payment_reminders = payment_reminders
        end

        def view_template
          div(id: "payment_reminders_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :xl) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Payment Reminders" }
                  render RubyUI::DialogDescription.new { "Manage automatic reminders for upcoming payments" }
                end

                render RubyUI::DialogMiddle.new do
                  render ::Views::Banking::PaymentReminders::TabsContent.new(payment_reminders: @payment_reminders)
                end
              end
            end
          end
        end
      end
    end
  end
end
