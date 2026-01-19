# frozen_string_literal: true

module Views
  module Banking
    module Categories
      class IndexDialog < ::Views::Base
        def initialize(categories:)
          @categories = categories
        end

        def view_template
          div(id: "categories_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Manage Categories" }
                  render RubyUI::DialogDescription.new do
                    plain "Create, edit, and delete categories for organizing your transactions"
                  end
                end

                render RubyUI::DialogMiddle.new do
                  div(id: "categories_content") do
                    render List.new(categories: @categories)
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
