# frozen_string_literal: true

module Views
  module Journals
    class Index < ::Views::Base
      def initialize(journals:, search_query: nil, page: 1)
        @journals = journals
        @search_query = search_query
        @page = page
      end

      def view_template
        div(class: "flex h-full flex-col p-4") do
          render ::Views::Journals::List.new(
            journals: @journals,
            search_query: @search_query,
            page: @page
          )
        end
      end
    end
  end
end
