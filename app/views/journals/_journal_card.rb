# frozen_string_literal: true

module Views
  module Journals
    class JournalCard < ::Views::Base
      def initialize(journal:)
        @journal = journal
      end

      def view_template
        a(
          href: view_context.journal_path(@journal),
          id: "journal_#{@journal.id}",
          class: "block p-4 bg-card border rounded-lg hover:bg-accent transition-colors"
        ) do
          div(class: "flex items-center justify-between") do
            div(class: "flex items-center gap-3") do
              render ::Components::Icon.new(name: :book_open, size: "16", class: "text-primary")
              div do
                h3(class: "font-semibold") { @journal.date_display }
                p(class: "text-sm text-muted-foreground") do
                  "#{@journal.journal_prompts.count} prompts · #{@journal.journal_fragments.count} entries"
                end
              end
            end
            render ::Components::Icon.new(name: :chevron_right, size: "16", class: "text-muted-foreground")
          end
        end
      end
    end
  end
end
