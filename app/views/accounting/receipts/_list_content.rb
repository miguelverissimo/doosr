module Views
  module Accounting
    module Receipts
      class ListContent < ::Views::Base
        def initialize(user:, page: 1, search_query: nil, invoice_number: nil, date_from: nil, date_to: nil, **attrs)
          @user = user
          @page = page
          @search_query = search_query
          @invoice_number = invoice_number
          @date_from = date_from
          @date_to = date_to

          receipts_query = user.receipts
            .includes(:invoice)
            .includes(:items)
            .includes(:receipt_items)

          # Apply search by receipt reference
          if search_query.present?
            receipts_query = receipts_query.where("reference ILIKE ?", "%#{search_query}%")
          end

          # Apply search by invoice number
          if invoice_number.present?
            receipts_query = receipts_query.joins(:invoice)
              .where("accounting_invoices.display_number ILIKE ?", "%#{invoice_number}%")
          end

          # Apply date range filter
          if date_from.present?
            receipts_query = receipts_query.where("issue_date >= ?", Date.parse(date_from))
          end

          if date_to.present?
            receipts_query = receipts_query.where("issue_date <= ?", Date.parse(date_to))
          end

          @receipts = receipts_query
            .order(issue_date: :desc)
            .page(page)
            .per(4)

          super(**attrs)
        end

        def view_template
          div(id: "receipts_list", data: { receipts_pagination_target: "content" }) do
            if @receipts.empty?
              div(class: "flex h-full flex-col items-center justify-center") do
                p(class: "text-sm text-gray-500") { "No receipts found" }
              end
            else
              @receipts.each do |receipt|
                render ::Views::Accounting::Receipts::ReceiptRow.new(receipt: receipt)
              end

              # Pagination
              if @receipts.total_pages > 1
                div(class: "mt-6") do
                  render_pagination
                end
              end
            end
          end
        end

        def render_pagination
          Pagination do
            PaginationContent do
              # First button
              unless @receipts.first_page?
                PaginationItem(
                  href: pagination_path(1),
                  data: {
                    turbo_stream: true,
                    action: "click->receipts-pagination#showSpinner"
                  }
                ) do
                  render ::Components::Icon::ChevronsLeft.new(size: "12", class: "w-5 h-5")
                  plain("First")
                end
              end

              # Previous button
              unless @receipts.first_page?
                PaginationItem(
                  href: pagination_path(@receipts.prev_page),
                  data: {
                    turbo_stream: true,
                    action: "click->receipts-pagination#showSpinner"
                  }
                ) do
                  render ::Components::Icon::ChevronLeft.new(size: "12", class: "w-5 h-5")
                  plain("Prev")
                end
              end

              # Page numbers
              render_page_numbers

              # Next button
              unless @receipts.last_page?
                PaginationItem(
                  href: pagination_path(@receipts.next_page),
                  data: {
                    turbo_stream: true,
                    action: "click->receipts-pagination#showSpinner"
                  }
                ) do
                  render ::Components::Icon::ChevronRight.new(size: "12", class: "w-5 h-5")
                  plain("Next")
                end
              end

              # Last button
              unless @receipts.last_page?
                PaginationItem(
                  href: pagination_path(@receipts.total_pages),
                  data: {
                    turbo_stream: true,
                    action: "click->receipts-pagination#showSpinner"
                  }
                ) do
                  render ::Components::Icon::ChevronsRight.new(size: "12", class: "w-5 h-5")
                  plain("Last")
                end
              end
            end
          end
        end

        def render_page_numbers
          current_page = @receipts.current_page
          total_pages = @receipts.total_pages

          # Show max 5 page numbers
          if total_pages <= 5
            (1..total_pages).each do |page_num|
              PaginationItem(
                href: pagination_path(page_num),
                active: page_num == current_page,
                data: {
                  turbo_stream: true,
                  action: "click->receipts-pagination#showSpinner"
                }
              ) { page_num.to_s }
            end
          else
            # Show first page
            PaginationItem(
              href: pagination_path(1),
              active: current_page == 1,
              data: {
                turbo_stream: true,
                action: "click->receipts-pagination#showSpinner"
              }
            ) { "1" }

            # Show ellipsis if needed
            PaginationEllipsis if current_page > 3

            # Show current page and neighbors
            start_page = [ current_page - 1, 2 ].max
            end_page = [ current_page + 1, total_pages - 1 ].min

            (start_page..end_page).each do |page_num|
              next if page_num == 1 || page_num == total_pages

              PaginationItem(
                href: pagination_path(page_num),
                active: page_num == current_page,
                data: {
                  turbo_stream: true,
                  action: "click->receipts-pagination#showSpinner"
                }
              ) { page_num.to_s }
            end

            # Show ellipsis if needed
            PaginationEllipsis if current_page < total_pages - 2

            # Show last page
            PaginationItem(
              href: pagination_path(total_pages),
              active: current_page == total_pages,
              data: {
                turbo_stream: true,
                action: "click->receipts-pagination#showSpinner"
              }
            ) { total_pages.to_s }
          end
        end

        def pagination_path(page)
          params = { page: page }
          params[:search_query] = @search_query if @search_query.present?
          params[:invoice_number] = @invoice_number if @invoice_number.present?
          params[:date_from] = @date_from if @date_from.present?
          params[:date_to] = @date_to if @date_to.present?
          view_context.receipts_path(params)
        end
      end
    end
  end
end
