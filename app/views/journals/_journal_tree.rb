# frozen_string_literal: true

module Views
  module Journals
    class JournalTree < ::Views::Base
      def initialize(journal:, tree:)
        @journal = journal
        @tree = tree
      end

      def view_template
        if @tree.children.empty?
          div(class: "flex h-full flex-col items-center justify-center py-12") do
            render ::Components::Icon::BookOpen.new(size: "24", class: "text-muted-foreground mb-4")
            p(class: "text-sm text-muted-foreground") { "No entries yet. Add your first entry or prompt above." }
          end
        else
          div(class: "space-y-3") do
            @tree.children.each do |node|
              render ::Views::Items::TreeNode.new(node: node)
            end
          end
        end
      end
    end
  end
end
