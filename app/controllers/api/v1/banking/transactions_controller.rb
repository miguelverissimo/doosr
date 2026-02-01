module Api
  module V1
    module Banking
      class TransactionsController < Api::BaseController
        before_action :authorize_banking_access!

        resource_description do
          short "Banking Transactions"
          description "Manage bank transactions"
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
        param :transfer_filter, String, desc: "Filter transfers: 'exclude' or 'only'", required: false
        param :min_amount, String, desc: "Minimum absolute amount", required: false
        param :max_amount, String, desc: "Maximum absolute amount", required: false
        def index
          start_date = parse_date_param(params[:start_date], (Date.current - 3.months).beginning_of_month)
          end_date = parse_date_param(params[:end_date], Date.current.end_of_month)
          page = (params[:page] || 1).to_i
          per_page = (params[:per_page] || 100).to_i

          transactions = current_user.bank_transactions
            .includes(:bank_account, transaction_categorizations: :category)

          if start_date && end_date
            transactions = transactions.where(date: start_date..end_date)
          elsif start_date
            transactions = transactions.where("date >= ?", start_date)
          elsif end_date
            transactions = transactions.where("date <= ?", end_date)
          end

          transactions = apply_filters(transactions)

          # Calculate totals (excluding transfers)
          non_transfer = transactions.non_transfers
          total_income = non_transfer.where("value > 0").sum(:value).to_f
          total_expenses = non_transfer.where("value < 0").sum(:value).abs.to_f

          total_count = transactions.count
          sorted = transactions.order(date: :desc, id: :desc)
          paginated = sorted.offset((page - 1) * per_page).limit(per_page)

          render json: {
            data: paginated.map { |t| serialize_transaction(t) },
            meta: {
              page: page,
              per_page: per_page,
              total_count: total_count,
              total_pages: (total_count.to_f / per_page).ceil,
              total_income: total_income.round(2),
              total_expenses: total_expenses.round(2),
              net_balance: (total_income - total_expenses).round(2)
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
          transaction.row_hash = generate_row_hash(transaction)

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
            transaction.update_column(:row_hash, generate_row_hash(transaction))

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

        private

        def authorize_banking_access!
          authorize_feature!(:banking)
        end

        def transaction_params
          params.require(:bank_transaction).permit(:date, :description, :value, :bank_account_id)
        end

        def generate_row_hash(transaction)
          normalized_value = transaction.value&.to_s("F") || "0"
          date_str = transaction.date&.iso8601 || ""
          desc_str = transaction.description&.downcase || ""
          data = "#{date_str}|#{desc_str}|#{normalized_value}"
          Digest::SHA256.hexdigest(data)
        end

        def apply_filters(transactions)
          if params[:category_id].present?
            if params[:category_id] == "uncategorized"
              transactions = transactions.without_categorizations
            else
              category = current_user.categories.find_by(id: params[:category_id])
              if category
                category_ids = category.self_and_subcategory_ids
                transactions = transactions.with_any_categorization(category_ids)
              end
            end
          end

          if params[:search].present?
            transactions = transactions.where("LOWER(description) LIKE ?", "%#{params[:search].downcase}%")
          end

          if params[:bank_account_id].present?
            if params[:bank_account_id] == "none"
              transactions = transactions.where(bank_account_id: nil)
            else
              transactions = transactions.where(bank_account_id: params[:bank_account_id])
            end
          end

          case params[:transfer_filter]
          when "exclude"
            transactions = transactions.non_transfers
          when "only"
            transactions = transactions.transfers
          end

          if params[:min_amount].present?
            transactions = transactions.where("ABS(value) >= ?", BigDecimal(params[:min_amount]))
          end

          if params[:max_amount].present?
            transactions = transactions.where("ABS(value) <= ?", BigDecimal(params[:max_amount]))
          end

          transactions
        end

        def parse_date_param(param, default)
          return nil if param == "all"
          return default if param.blank?
          param.to_date
        rescue ArgumentError
          default
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
