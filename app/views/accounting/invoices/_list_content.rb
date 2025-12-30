module Views
  module Accounting
    module Invoices
      class ListContent < ::Views::Base
        def initialize(user:, filter: "unpaid", page: 1, search_query: nil, date_from: nil, date_to: nil, **attrs)
          @user = user
          @filter = filter
          @page = page
          @search_query = search_query
          @date_from = date_from
          @date_to = date_to

          # If search is active, search ALL records ignoring filter
          # Otherwise, apply the filter
          has_search = search_query.present? || date_from.present? || date_to.present?

          invoices_query = if has_search
            # Search over ALL invoices, ignoring filter
            user.invoices
          else
            # No search - apply filter
            case filter
            when "paid"
              user.invoices.where(state: :paid)
            when "all"
              user.invoices
            else # "unpaid" is default
              user.invoices.where.not(state: :paid)
            end
          end

          # Apply search by invoice number
          if search_query.present?
            invoices_query = invoices_query.where("display_number ILIKE ?", "%#{search_query}%")
          end

          # Apply date range filter
          if date_from.present?
            invoices_query = invoices_query.where("issued_at >= ?", Date.parse(date_from))
          end

          if date_to.present?
            invoices_query = invoices_query.where("issued_at <= ?", Date.parse(date_to))
          end

          @invoices = invoices_query
            .includes(:invoice_items, :items, :receipts)
            .order(year: :desc, number: :desc)
            .page(page)
            .per(4)

          # Query receipt items once for all forms
          @receipt_items = {
            manev_h: user.receipt_items.find_by(reference: "OUT - MANEV-H"),
            manev_on_call: user.receipt_items.find_by(reference: "OUT - MANEV-ON-CALL"),
            token: user.receipt_items.find_by(reference: "OUT - TOKEN")
          }

          # Query available invoices once for all forms
          @available_invoices = user.invoices
            .where(state: :paid)
            .where.not(id: ::Accounting::Receipt.where.not(invoice_id: nil).select(:invoice_id))
            .order(year: :desc, number: :desc)
            .to_a

          super(**attrs)
        end

        def view_template
          if @invoices.empty?
            div(class: "flex h-full flex-col items-center justify-center") do
              p(class: "text-sm text-gray-500") { "No invoices found" }
            end
          else
            @invoices.each do |invoice|
              render ::Views::Accounting::Invoices::InvoiceRow.new(
                invoice: invoice,
                receipt_items: @receipt_items,
                available_invoices: @available_invoices,
                filter: @filter,
                page: @page
              )
            end

            # Pagination
            if @invoices.total_pages > 1
              div(class: "mt-6") do
                render_pagination
              end
            end
          end
        end

        def render_pagination
          Pagination do
            PaginationContent do
              # First button
              unless @invoices.first_page?
                PaginationItem(
                  href: pagination_path(1),
                  data: {
                    turbo_stream: true,
                    action: "click->invoice-filter#showSpinner"
                  }
                ) do
                  render ::Components::Icon.new(name: :chevrons_left, size: "12", class: "w-5 h-5")
                  plain("First")
                end
              end

              # Previous button
              unless @invoices.first_page?
                PaginationItem(
                  href: pagination_path(@invoices.prev_page),
                  data: {
                    turbo_stream: true,
                    action: "click->invoice-filter#showSpinner"
                  }
                ) do
                  render ::Components::Icon.new(name: :chevron_left, size: "12", class: "w-5 h-5")
                  plain("Prev")
                end
              end

              # Page numbers
              render_page_numbers

              # Next button
              unless @invoices.last_page?
                PaginationItem(
                  href: pagination_path(@invoices.next_page),
                  data: {
                    turbo_stream: true,
                    action: "click->invoice-filter#showSpinner"
                  }
                ) do
                  render ::Components::Icon.new(name: :chevron_right, size: "12", class: "w-5 h-5")
                  plain("Next")
                end
              end

              # Last button
              unless @invoices.last_page?
                PaginationItem(
                  href: pagination_path(@invoices.total_pages),
                  data: {
                    turbo_stream: true,
                    action: "click->invoice-filter#showSpinner"
                  }
                ) do
                  render ::Components::Icon.new(name: :chevrons_right, size: "12", class: "w-5 h-5")
                  plain("Last")
                end
              end
            end
          end
        end

        def render_page_numbers
          current_page = @invoices.current_page
          total_pages = @invoices.total_pages

          # Show max 5 page numbers
          if total_pages <= 5
            (1..total_pages).each do |page_num|
              PaginationItem(
                href: pagination_path(page_num),
                active: page_num == current_page,
                data: {
                  turbo_stream: true,
                  action: "click->invoice-filter#showSpinner"
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
                action: "click->invoice-filter#showSpinner"
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
                  action: "click->invoice-filter#showSpinner"
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
                action: "click->invoice-filter#showSpinner"
              }
            ) { total_pages.to_s }
          end
        end

        def pagination_path(page)
          params = { filter: @filter, page: page }
          params[:search_query] = @search_query if @search_query.present?
          params[:date_from] = @date_from if @date_from.present?
          params[:date_to] = @date_to if @date_to.present?
          view_context.invoices_path(params)
        end
      end
    end
  end
end
