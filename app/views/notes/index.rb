# frozen_string_literal: true

module Views
  module Notes
    class Index < ::Views::Base
      def initialize(notes:, search_query: nil, page: 1)
        @notes = notes
        @search_query = search_query
        @page = page
      end

      def view_template
        div(class: "flex h-full flex-col p-4") do
          render ::Views::Notes::List.new(
            notes: @notes,
            search_query: @search_query,
            page: @page
          )
        end
      end
    end
  end
end
