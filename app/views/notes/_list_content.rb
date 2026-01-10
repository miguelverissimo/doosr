# frozen_string_literal: true

module Views
  module Notes
    class ListContent < ::Views::Base
      def initialize(notes:, search_query: nil, page: 1)
        @notes = notes
        @search_query = search_query
        @page = page
      end

      def view_template
        if @notes.empty?
          div(class: "flex h-full flex-col items-center justify-center") do
            p(class: "text-sm text-muted-foreground") do
              @search_query.present? ? "No notes found matching your search" : "No notes yet. Create your first note!"
            end
          end
        else
          div(class: "space-y-2") do
            @notes.each do |note|
              render ::Views::Notes::NoteRow.new(
                note: note,
                search_query: @search_query,
                page: @page
              )
            end
          end

          # Pagination
          if @notes.total_pages > 1
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
            unless @notes.first_page?
              PaginationItem(
                href: pagination_path(@notes.prev_page),
                data: {
                  turbo_stream: true,
                  action: "click->note-search#showSpinner"
                }
              ) do
                render ::Components::Icon::ChevronLeft.new(size: "12", class: "w-5 h-5")
                plain("Prev")
              end
            end

            # Page numbers
            render_page_numbers

            # Next button
            unless @notes.last_page?
              PaginationItem(
                href: pagination_path(@notes.next_page),
                data: {
                  turbo_stream: true,
                  action: "click->note-search#showSpinner"
                }
              ) do
                render ::Components::Icon::ChevronRight.new(size: "12", class: "w-5 h-5")
                plain("Next")
              end
            end
          end
        end
      end

      def render_page_numbers
        current_page = @notes.current_page
        total_pages = @notes.total_pages

        # Show max 5 page numbers
        if total_pages <= 5
          (1..total_pages).each do |page_num|
            PaginationItem(
              href: pagination_path(page_num),
              active: page_num == current_page,
              data: {
                turbo_stream: true,
                action: "click->note-search#showSpinner"
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
                action: "click->note-search#showSpinner"
              }
            ) { page_num.to_s }
          end
        end
      end

      def pagination_path(page)
        params = { page: page }
        params[:search_query] = @search_query if @search_query.present?
        view_context.notes_path(params)
      end
    end
  end
end
