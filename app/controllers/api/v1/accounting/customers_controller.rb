module Api
  module V1
    module Accounting
      class CustomersController < Api::BaseController
        before_action :authorize_accounting_access!

        resource_description do
          short "Customers"
          description "Manage accounting customers"
          meta group: "Accounting"
          formats [ "json" ]
        end

        api :GET, "/accounting/customers", "List all customers"
        description "Returns all customers for the authenticated user, ordered by name."
        def index
          customers = ::Accounting::Customer.where(user: current_user)
            .includes(:address)
            .order(:name)

          render json: {
            data: customers.map { |c| serialize_customer(c) },
            meta: { total_count: customers.count }
          }, status: :ok
        end

        api :GET, "/accounting/customers/:id", "Show a customer"
        description "Returns a single customer by ID."
        param :id, :number, desc: "Customer ID", required: true
        def show
          customer = ::Accounting::Customer.where(user: current_user).find(params[:id])

          render json: {
            data: serialize_customer(customer),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        private

        def authorize_accounting_access!
          authorize_feature!(:accounting)
        end

        def serialize_customer(customer)
          {
            id: customer.id,
            name: customer.name,
            address: customer.address ? {
              id: customer.address.id,
              name: customer.address.name,
              full_address: customer.address.full_address,
              country: customer.address.country
            } : nil,
            created_at: customer.created_at.iso8601,
            updated_at: customer.updated_at.iso8601
          }
        end
      end
    end
  end
end
