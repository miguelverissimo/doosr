# frozen_string_literal: true

module Api
  module V1
    module Banking
      class PlannedExpensesController < Api::BaseController
        before_action :authorize_banking_access!

        resource_description do
          short "Planned Expenses"
          description "Manage planned expenses"
          meta group: "Banking"
          formats [ "json" ]
        end

        api :GET, "/banking/planned_expenses", "List planned expenses"
        description "Returns planned expenses with optional status filter."
        param :status, String, desc: "Filter by status: 'pending', 'completed', or 'all' (default: all)", required: false
        def index
          expenses = current_user.planned_expenses
            .includes(:category, :recurring_group)
            .order(due_date: :asc)

          case params[:status]
          when "pending"
            expenses = expenses.where(completed: false)
          when "completed"
            expenses = expenses.where(completed: true)
          end

          render json: {
            data: expenses.map { |e| serialize_planned_expense(e) },
            meta: { total_count: expenses.count }
          }, status: :ok
        end

        api :GET, "/banking/planned_expenses/:id", "Show a planned expense"
        param :id, :number, desc: "Planned expense ID", required: true
        def show
          expense = current_user.planned_expenses.includes(:category, :recurring_group).find(params[:id])

          render json: {
            data: serialize_planned_expense(expense),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :POST, "/banking/planned_expenses", "Create a planned expense"
        param :planned_expense, Hash, desc: "Planned expense attributes", required: true do
          param :description, String, desc: "Expense description", required: true
          param :expected_amount, :number, desc: "Expected amount", required: true
          param :due_date, String, desc: "Due date (YYYY-MM-DD)", required: true
          param :category_id, :number, desc: "Category ID", required: false
          param :completed, :boolean, desc: "Whether expense is completed", required: false
        end
        def create
          expense = current_user.planned_expenses.build(planned_expense_params)
          expense.expense_type = "one_time"

          if expense.save
            render json: {
              data: serialize_planned_expense(expense),
              meta: {}
            }, status: :created
          else
            render_error(
              expense.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: expense.errors.full_messages
            )
          end
        end

        api :PATCH, "/banking/planned_expenses/:id", "Update a planned expense"
        param :id, :number, desc: "Planned expense ID", required: true
        param :planned_expense, Hash, desc: "Planned expense attributes", required: true do
          param :description, String, desc: "Expense description", required: false
          param :expected_amount, :number, desc: "Expected amount", required: false
          param :due_date, String, desc: "Due date (YYYY-MM-DD)", required: false
          param :category_id, :number, desc: "Category ID", required: false
          param :completed, :boolean, desc: "Whether expense is completed", required: false
        end
        def update
          expense = current_user.planned_expenses.find(params[:id])

          if expense.update(planned_expense_params)
            render json: {
              data: serialize_planned_expense(expense),
              meta: {}
            }, status: :ok
          else
            render_error(
              expense.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: expense.errors.full_messages
            )
          end
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :DELETE, "/banking/planned_expenses/:id", "Delete a planned expense"
        param :id, :number, desc: "Planned expense ID", required: true
        def destroy
          expense = current_user.planned_expenses.find(params[:id])
          expense.destroy!

          render json: { data: nil, meta: {} }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :PATCH, "/banking/planned_expenses/:id/mark_completed", "Mark expense as completed"
        param :id, :number, desc: "Planned expense ID", required: true
        def mark_completed
          expense = current_user.planned_expenses.find(params[:id])
          expense.mark_completed!

          render json: {
            data: serialize_planned_expense(expense),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :POST, "/banking/planned_expenses/populate_from_recurring", "Populate from recurring groups"
        description "Creates planned expenses from recurring transaction groups."
        def populate_from_recurring
          result = ::Banking::PlannedExpensePopulatorService.new(current_user).call

          if result.success
            render json: {
              data: nil,
              meta: {
                created_count: result.created_count,
                skipped_count: result.skipped_count
              }
            }, status: :ok
          else
            render_error(
              result.errors.join(", "),
              status: :unprocessable_entity,
              errors: result.errors
            )
          end
        end

        private

        def authorize_banking_access!
          authorize_feature!(:banking)
        end

        def planned_expense_params
          params.require(:planned_expense).permit(:description, :expected_amount, :due_date, :category_id, :completed)
        end

        def serialize_planned_expense(expense)
          {
            id: expense.id,
            description: expense.description,
            expected_amount: expense.expected_amount&.to_f,
            due_date: expense.due_date&.to_s,
            expense_type: expense.expense_type,
            completed: expense.completed,
            category_id: expense.category_id,
            category_name: expense.category&.name,
            recurring_group_id: expense.recurring_group_id,
            recurring_group_name: expense.recurring_group&.name,
            created_at: expense.created_at.iso8601,
            updated_at: expense.updated_at.iso8601
          }
        end
      end
    end
  end
end
