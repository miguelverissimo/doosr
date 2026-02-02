# frozen_string_literal: true

module Api
  module V1
    module Banking
      class TransactionsController < Api::BaseController
        before_action :authorize_banking_access!

        resource_description do
          short "Transactions"
          description "Manage bank transactions"
          meta group: "Banking"
          formats [ "json" ]
        end

        api :GET, "/banking/transactions", "List transactions"
        description "Returns paginated transactions with filtering by date range, category, account, and more."
        param_group :pagination, Api::BaseController
        param :start_date, String, desc: "Start date (YYYY-MM-DD) or 'all' for no limit", required: false
        param :end_date, String, desc: "End date (YYYY-MM-DD) or 'all' for no limit", required: false
        param :category_id, String, desc: "Filter by category ID, or 'uncategorized'", required: false
        param :search, String, desc: "Search by description", required: false
        param :bank_account_id, String, desc: "Filter by bank account ID, or 'none'", required: false
        param :transfer_filter, String, desc: "Filter transfers: 'exclude', 'only', or 'include'", required: false
        param :min_amount, String, desc: "Minimum absolute amount", required: false
        param :max_amount, String, desc: "Maximum absolute amount", required: false
        param :sort, String, desc: "Sort column (date, description, category, value)", required: false
        param :direction, String, desc: "Sort direction (asc, desc)", required: false
        def index
          query_service = ::Banking::TransactionQueryService.new(current_user, query_params)
          result = query_service.query

          render json: {
            data: result.transactions.map { |t| serialize_transaction(t) },
            meta: {
              page: query_service.page.to_i,
              per_page: query_service.per_page.to_i,
              total_count: result.total_count,
              total_pages: (result.total_count.to_f / query_service.per_page.to_i).ceil,
              total_income: result.total_income.to_f.round(2),
              total_expenses: result.total_expenses.to_f.round(2),
              net_balance: result.net_balance.to_f.round(2)
            }
          }, status: :ok
        end

        api :GET, "/banking/transactions/:id", "Show a transaction"
        description "Returns a single transaction by ID."
        param :id, :number, desc: "Transaction ID", required: true
        def show
          transaction = current_user.bank_transactions.find(params[:id])

          render json: {
            data: serialize_transaction(transaction),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :POST, "/banking/transactions", "Create a transaction"
        description "Creates a new bank transaction."
        param :bank_transaction, Hash, desc: "Transaction attributes", required: true do
          param :date, String, desc: "Transaction date (YYYY-MM-DD)", required: true
          param :description, String, desc: "Transaction description", required: true
          param :value, :number, desc: "Transaction value (positive for income, negative for expense)", required: true
          param :bank_account_id, :number, desc: "Bank account ID", required: false
        end
        param :category_id, :number, desc: "Category ID to assign", required: false
        def create
          transaction = current_user.bank_transactions.build(transaction_params)
          transaction.row_hash = ::Banking::TransactionRowHashService.generate_from_transaction(transaction)

          if transaction.save
            if params[:category_id].present?
              transaction.set_categories([ params[:category_id] ])
            end

            render json: {
              data: serialize_transaction(transaction.reload),
              meta: {}
            }, status: :created
          else
            render_error(
              transaction.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: transaction.errors.full_messages
            )
          end
        end

        api :PATCH, "/banking/transactions/:id", "Update a transaction"
        description "Updates an existing bank transaction."
        param :id, :number, desc: "Transaction ID", required: true
        param :bank_transaction, Hash, desc: "Transaction attributes", required: true do
          param :date, String, desc: "Transaction date (YYYY-MM-DD)", required: false
          param :description, String, desc: "Transaction description", required: false
          param :value, :number, desc: "Transaction value", required: false
          param :bank_account_id, :number, desc: "Bank account ID", required: false
        end
        param :category_id, :number, desc: "Category ID to assign (null to clear)", required: false
        def update
          transaction = current_user.bank_transactions.find(params[:id])

          if transaction.update(transaction_params)
            transaction.update_column(:row_hash, ::Banking::TransactionRowHashService.generate_from_transaction(transaction))

            if params.key?(:category_id)
              if params[:category_id].present?
                transaction.set_categories([ params[:category_id] ])
              else
                transaction.transaction_categorizations.destroy_all
              end
            end

            render json: {
              data: serialize_transaction(transaction.reload),
              meta: {}
            }, status: :ok
          else
            render_error(
              transaction.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: transaction.errors.full_messages
            )
          end
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :DELETE, "/banking/transactions/:id", "Delete a transaction"
        description "Permanently deletes a bank transaction."
        param :id, :number, desc: "Transaction ID", required: true
        def destroy
          transaction = current_user.bank_transactions.find(params[:id])
          transaction.destroy!

          render json: { data: nil, meta: {} }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :PATCH, "/banking/transactions/:id/toggle_transfer", "Toggle transfer flag"
        description "Toggles whether a transaction is marked as a transfer."
        param :id, :number, desc: "Transaction ID", required: true
        def toggle_transfer
          transaction = current_user.bank_transactions.find(params[:id])
          transaction.update!(is_transfer: !transaction.is_transfer)

          render json: {
            data: serialize_transaction(transaction.reload),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :PATCH, "/banking/transactions/:id/update_category", "Update transaction category"
        description "Sets or clears the primary category for a transaction."
        param :id, :number, desc: "Transaction ID", required: true
        param :category_id, :number, desc: "Category ID (omit or null to clear)", required: false
        def update_category
          transaction = current_user.bank_transactions.find(params[:id])

          if params[:category_id].present?
            transaction.set_categories([ params[:category_id] ])
          else
            transaction.transaction_categorizations.destroy_all
          end

          render json: {
            data: serialize_transaction(transaction.reload),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :PATCH, "/banking/transactions/:id/update_categories", "Update transaction categories with splits"
        description "Sets multiple categories with optional split amounts."
        param :id, :number, desc: "Transaction ID", required: true
        param :category_ids, Array, of: :number, desc: "Array of category IDs", required: true
        param :amounts, Hash, desc: "Hash of category_id => amount for split categorization", required: false
        def update_categories
          transaction = current_user.bank_transactions.find(params[:id])
          category_ids = Array(params[:category_ids]).reject(&:blank?)
          amounts = params[:amounts] || {}

          transaction.set_categories(category_ids, amounts)

          render json: {
            data: serialize_transaction(transaction.reload),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        rescue StandardError => e
          render_error(e.message, status: :unprocessable_entity)
        end

        api :DELETE, "/banking/transactions/bulk_destroy", "Bulk delete transactions"
        description "Deletes multiple transactions by ID."
        param :ids, Array, of: :number, desc: "Array of transaction IDs to delete", required: true
        def bulk_destroy
          ids = Array(params[:ids]).map(&:to_i)
          transactions = current_user.bank_transactions.where(id: ids)
          destroyed_count = transactions.count
          transactions.destroy_all

          render json: {
            data: nil,
            meta: { destroyed_count: destroyed_count }
          }, status: :ok
        end

        api :POST, "/banking/transactions/import_csv", "Import transactions from CSV"
        description "Imports transactions from a CSV file. Processing happens asynchronously."
        param :csv_file, File, desc: "CSV file to import", required: true
        param :bank_account_id, :number, desc: "Bank account ID to associate imports with", required: false
        def import_csv
          csv_file = params[:csv_file]

          if csv_file.blank?
            render_error("Please provide a CSV file", status: :unprocessable_entity)
            return
          end

          csv_content = csv_file.read
          bank_account_id = params[:bank_account_id].presence

          ::Banking::ImportJob.perform_later(current_user.id, csv_content, bank_account_id: bank_account_id)

          render json: {
            data: nil,
            meta: { message: "CSV import started. Processing will happen in the background." }
          }, status: :accepted
        end

        api :GET, "/banking/transactions/analytics", "Get transaction analytics"
        description "Returns category breakdown, time series data, and period-over-period stats."
        param :start_date, String, desc: "Start date (YYYY-MM-DD) or 'all'", required: false
        param :end_date, String, desc: "End date (YYYY-MM-DD) or 'all'", required: false
        param :category_id, String, desc: "Filter by category ID", required: false
        param :breakdown_parent_id, String, desc: "Show subcategory breakdown for this parent", required: false
        param :bank_account_id, String, desc: "Filter by bank account ID", required: false
        param :transfer_filter, String, desc: "Filter transfers: 'exclude', 'only', or 'include'", required: false
        param :min_amount, String, desc: "Minimum absolute amount", required: false
        param :max_amount, String, desc: "Maximum absolute amount", required: false
        param :search, String, desc: "Search by description", required: false
        def analytics
          query_service = ::Banking::TransactionQueryService.new(current_user, query_params)
          result = query_service.call

          render json: {
            data: {
              total_income: result.total_income.to_f.round(2),
              total_expenses: result.total_expenses.to_f.round(2),
              net_balance: result.net_balance.to_f.round(2),
              income_change: result.income_change,
              expenses_change: result.expenses_change,
              balance_change: result.balance_change,
              category_breakdown: result.category_breakdown,
              time_series: {
                data: result.time_series_data,
                granularity: result.time_series_granularity
              }
            },
            meta: {
              start_date: query_service.start_date&.to_s,
              end_date: query_service.end_date&.to_s
            }
          }, status: :ok
        end

        private

        def authorize_banking_access!
          authorize_feature!(:banking)
        end

        def transaction_params
          params.require(:bank_transaction).permit(:date, :description, :value, :bank_account_id)
        end

        def query_params
          params.permit(:start_date, :end_date, :page, :per_page, :sort, :direction,
                        :category_id, :breakdown_parent_id, :min_amount, :max_amount,
                        :search, :bank_account_id, :transfer_filter).to_h.symbolize_keys
        end

        def serialize_transaction(transaction)
          {
            id: transaction.id,
            date: transaction.date.to_s,
            description: transaction.description,
            value: transaction.value.to_f,
            is_transfer: transaction.is_transfer,
            bank_account_id: transaction.bank_account_id,
            bank_account_name: transaction.bank_account&.name,
            categories: transaction.transaction_categorizations.map { |tc|
              {
                id: tc.category_id,
                name: tc.category&.name,
                amount: tc.amount&.to_f
              }
            },
            created_at: transaction.created_at.iso8601,
            updated_at: transaction.updated_at.iso8601
          }
        end
      end
    end
  end
end
