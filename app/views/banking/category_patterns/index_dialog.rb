# frozen_string_literal: true

module Views
  module Banking
    module CategoryPatterns
      class IndexDialog < ::Views::Base
        def initialize(category_patterns:)
          @category_patterns = category_patterns
        end

        def view_template
          div(id: "category_patterns_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Manage Patterns" }
                  render RubyUI::DialogDescription.new do
                    plain "View and manage auto-categorization patterns for your transactions"
                  end
                end

                render RubyUI::DialogMiddle.new do
                  render List.new(category_patterns: @category_patterns)
                end
              end
            end
          end
        end
      end
    end
  end
end
