module Api
  module V1
    module Accounting
      class InvoicesController < Api::BaseController
        before_action :authorize_accounting_access!

        resource_description do
          short "Invoices"
          description "Manage accounting invoices"
          meta group: "Accounting"
          formats [ "json" ]
        end

        api :GET, "/accounting/invoices", "List invoices"
        description "Returns paginated invoices with optional filtering by state, year, or customer."
        param_group :pagination, Api::BaseController
        param :filter, String, desc: "Filter by state: all, unpaid, paid, draft, sent", required: false
        param :year, :number, desc: "Filter by invoice year", required: false
        param :customer_id, :number, desc: "Filter by customer ID", required: false
        def index
          filter = params[:filter] || "all"
          page = (params[:page] || 1).to_i
          per_page = (params[:per_page] || 25).to_i

          invoices = current_user.invoices.includes(:customer, :invoice_items).order(year: :desc, number: :desc)

          case filter
          when "unpaid"
            invoices = invoices.where.not(state: :paid)
          when "paid"
            invoices = invoices.where(state: :paid)
          when "draft"
            invoices = invoices.where(state: :draft)
          when "sent"
            invoices = invoices.where(state: :sent)
          end

          if params[:year].present?
            invoices = invoices.where(year: params[:year])
          end

          if params[:customer_id].present?
            invoices = invoices.where(customer_id: params[:customer_id])
          end

          total_count = invoices.count
          paginated = invoices.offset((page - 1) * per_page).limit(per_page)

          render json: {
            data: paginated.map { |inv| serialize_invoice(inv) },
            meta: {
              page: page,
              per_page: per_page,
              total_count: total_count,
              total_pages: (total_count.to_f / per_page).ceil
            }
          }, status: :ok
        end

        api :GET, "/accounting/invoices/:id", "Show an invoice"
        description "Returns a single invoice with line items."
        param :id, :number, desc: "Invoice ID", required: true
        def show
          invoice = current_user.invoices.includes(:customer, :invoice_items).find(params[:id])

          render json: {
            data: serialize_invoice_detail(invoice),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :PATCH, "/accounting/invoices/:id", "Update an invoice"
        description "Update invoice state, notes, or dates."
        param :id, :number, desc: "Invoice ID", required: true
        param :invoice, Hash, desc: "Invoice attributes", required: true do
          param :state, String, desc: "Invoice state (draft, sent, paid)", required: false
          param :notes, String, desc: "Invoice notes", required: false
          param :due_at, String, desc: "Due date (ISO 8601)", required: false
          param :issued_at, String, desc: "Issue date (ISO 8601)", required: false
        end
        def update
          invoice = current_user.invoices.find(params[:id])

          if invoice.update(invoice_update_params)
            render json: {
              data: serialize_invoice(invoice.reload),
              meta: {}
            }, status: :ok
          else
            render_error(
              invoice.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: invoice.errors.full_messages
            )
          end
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :DELETE, "/accounting/invoices/:id", "Delete an invoice"
        description "Permanently deletes an invoice."
        param :id, :number, desc: "Invoice ID", required: true
        def destroy
          invoice = current_user.invoices.find(params[:id])
          invoice.destroy!

          render json: { data: nil, meta: {} }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        private

        def authorize_accounting_access!
          authorize_feature!(:accounting)
        end

        def invoice_update_params
          params.require(:invoice).permit(:state, :notes, :due_at, :issued_at)
        end

        def serialize_invoice(invoice)
          {
            id: invoice.id,
            number: invoice.number,
            display_number: invoice.display_number,
            year: invoice.year,
            state: invoice.state,
            currency: invoice.currency,
            subtotal: invoice.subtotal&.to_f,
            discount: invoice.discount&.to_f,
            tax: invoice.tax&.to_f,
            total: invoice.total&.to_f,
            customer_name: invoice.customer&.name,
            customer_id: invoice.customer_id,
            issued_at: invoice.issued_at&.iso8601,
            due_at: invoice.due_at&.iso8601,
            overdue: invoice.overdue?,
            created_at: invoice.created_at.iso8601,
            updated_at: invoice.updated_at.iso8601
          }
        end

        def serialize_invoice_detail(invoice)
          data = serialize_invoice(invoice)

          data[:items] = invoice.invoice_items.includes(:item).map do |ii|
            {
              id: ii.id,
              description: ii.item&.description || ii.description,
              quantity: ii.quantity&.to_f,
              unit_price: ii.unit_price&.to_f,
              total: ii.total&.to_f
            }
          end

          data[:notes] = invoice.notes

          data
        end
      end
    end
  end
end
