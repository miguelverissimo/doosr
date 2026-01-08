# frozen_string_literal: true

module Views
  module Journals
    class JournalLinkItem < ::Views::Base
      def initialize(journal:, day: nil, list: nil, is_public_list: false)
        @journal = journal
        @day = day
        @list = list
        @is_public_list = is_public_list
      end

      def view_template
        a(
          href: view_context.journal_path(@journal),
          id: "journal_#{@journal.id}",
          class: "flex items-center gap-3 p-3 bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg hover:bg-purple-100 dark:hover:bg-purple-900/30 transition-colors"
        ) do
          render ::Components::Icon.new(name: :book_open, size: "16", class: "text-purple-600 dark:text-purple-400")

          div(class: "flex-1 min-w-0") do
            p(class: "font-medium text-purple-900 dark:text-purple-100") do
              "Journal: #{@journal.date.strftime('%B %d, %Y')}"
            end
            p(class: "text-sm text-purple-700 dark:text-purple-300") do
              "#{@journal.journal_fragments.count} entries"
            end
          end

          render ::Components::Icon.new(name: :chevron_right, size: "16", class: "text-purple-600 dark:text-purple-400")
        end
      end
    end
  end
end
