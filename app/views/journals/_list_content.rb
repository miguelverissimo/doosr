# frozen_string_literal: true

module Views
  module Journals
    class ListContent < ::Views::Base
      def initialize(journals:, search_query: nil, page: 1)
        @journals = journals
        @search_query = search_query
        @page = page
      end

      def view_template
        if @journals.empty?
          div(class: "flex h-full flex-col items-center justify-center") do
            p(class: "text-sm text-muted-foreground") do
              @search_query.present? ? "No journals found matching your search" : "No journals yet. Create your first entry!"
            end
          end
        else
          div(id: "journals_list", class: "space-y-2") do
            @journals.each do |journal|
              render ::Views::Journals::JournalCard.new(journal: journal)
            end
          end

          # Pagination
          if @journals.total_pages > 1
            div(class: "mt-6") do
              render_pagination
            end
          end
        end
      end

      private

      def render_pagination
        Pagination do
          PaginationContent do
            # Previous button
            unless @journals.first_page?
              PaginationItem(
                href: pagination_path(@journals.prev_page),
                data: {
                  turbo_stream: true,
                  action: "click->journal-search#showSpinner"
                }
              ) do
                render ::Components::Icon.new(name: :chevron_left, size: "12", class: "w-5 h-5")
                plain("Prev")
              end
            end

            # Page numbers
            render_page_numbers

            # Next button
            unless @journals.last_page?
              PaginationItem(
                href: pagination_path(@journals.next_page),
                data: {
                  turbo_stream: true,
                  action: "click->journal-search#showSpinner"
                }
              ) do
                render ::Components::Icon.new(name: :chevron_right, size: "12", class: "w-5 h-5")
                plain("Next")
              end
            end
          end
        end
      end

      def render_page_numbers
        current_page = @journals.current_page
        total_pages = @journals.total_pages

        # Show max 5 page numbers
        if total_pages <= 5
          (1..total_pages).each do |page_num|
            PaginationItem(
              href: pagination_path(page_num),
              active: page_num == current_page,
              data: {
                turbo_stream: true,
                action: "click->journal-search#showSpinner"
              }
            ) { page_num.to_s }
          end
        else
          # Show first, last, current and neighbors
          [ 1, current_page - 1, current_page, current_page + 1, total_pages ].uniq.select { |p| p.between?(1, total_pages) }.each do |page_num|
            PaginationItem(
              href: pagination_path(page_num),
              active: page_num == current_page,
              data: {
                turbo_stream: true,
                action: "click->journal-search#showSpinner"
              }
            ) { page_num.to_s }
          end
        end
      end

      def pagination_path(page)
        params = { page: page }
        params[:search_query] = @search_query if @search_query.present?
        view_context.journals_path(params)
      end
    end
  end
end
