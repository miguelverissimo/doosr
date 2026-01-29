# frozen_string_literal: true

module Views
  module Banking
    module TransferPatterns
      class IndexDialog < ::Views::Base
        def initialize(transfer_patterns:)
          @transfer_patterns = transfer_patterns
        end

        def view_template
          div(id: "transfer_patterns_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Transfer Patterns" }
                  render RubyUI::DialogDescription.new do
                    plain "Define patterns to automatically identify internal transfers. Transfers are excluded from income/expense totals."
                  end
                end

                render RubyUI::DialogMiddle.new do
                  render List.new(transfer_patterns: @transfer_patterns)
                end
              end
            end
          end
        end
      end
    end
  end
end
