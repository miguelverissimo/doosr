# frozen_string_literal: true

module Api
  module V1
    module Banking
      class BudgetGoalsController < Api::BaseController
        before_action :authorize_banking_access!

        resource_description do
          short "Budget Goals"
          description "Manage budget goals"
          meta group: "Banking"
          formats [ "json" ]
        end

        api :GET, "/banking/budget_goals", "List budget goals"
        description "Returns budget goals with category info and progress."
        def index
          goals = current_user.budget_goals.includes(:category).order(:goal_type, :created_at)
          progress_list = ::Banking::GoalProgressService.new(current_user).call

          progress_by_goal = progress_list.index_by { |p| p.goal.id }

          render json: {
            data: goals.map { |g| serialize_budget_goal(g, progress_by_goal[g.id]) },
            meta: { total_count: goals.count }
          }, status: :ok
        end

        api :GET, "/banking/budget_goals/:id", "Show a budget goal"
        param :id, :number, desc: "Budget goal ID", required: true
        def show
          goal = current_user.budget_goals.includes(:category).find(params[:id])
          progress = ::Banking::GoalProgressService.new(current_user).progress_for(goal)

          render json: {
            data: serialize_budget_goal(goal, progress),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :POST, "/banking/budget_goals", "Create a budget goal"
        param :budget_goal, Hash, desc: "Budget goal attributes", required: true do
          param :name, String, desc: "Goal name", required: true
          param :goal_type, String, desc: "Goal type (savings, category_limit)", required: true
          param :category_id, :number, desc: "Category ID", required: false
          param :target_amount, :number, desc: "Target amount", required: true
          param :period, String, desc: "Period (weekly, monthly, quarterly, yearly, custom)", required: true
          param :active, :boolean, desc: "Whether goal is active", required: false
          param :start_date, String, desc: "Start date (YYYY-MM-DD)", required: false
          param :payment_months, Array, of: :number, desc: "Payment months for custom period", required: false
        end
        def create
          goal = current_user.budget_goals.build(budget_goal_params)

          if goal.save
            render json: {
              data: serialize_budget_goal(goal),
              meta: {}
            }, status: :created
          else
            render_error(
              goal.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: goal.errors.full_messages
            )
          end
        end

        api :PATCH, "/banking/budget_goals/:id", "Update a budget goal"
        param :id, :number, desc: "Budget goal ID", required: true
        param :budget_goal, Hash, desc: "Budget goal attributes", required: true do
          param :name, String, desc: "Goal name", required: false
          param :goal_type, String, desc: "Goal type", required: false
          param :category_id, :number, desc: "Category ID", required: false
          param :target_amount, :number, desc: "Target amount", required: false
          param :period, String, desc: "Period", required: false
          param :active, :boolean, desc: "Whether goal is active", required: false
          param :start_date, String, desc: "Start date", required: false
          param :payment_months, Array, of: :number, desc: "Payment months", required: false
        end
        def update
          goal = current_user.budget_goals.find(params[:id])

          if goal.update(budget_goal_params)
            render json: {
              data: serialize_budget_goal(goal),
              meta: {}
            }, status: :ok
          else
            render_error(
              goal.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: goal.errors.full_messages
            )
          end
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :DELETE, "/banking/budget_goals/:id", "Delete a budget goal"
        param :id, :number, desc: "Budget goal ID", required: true
        def destroy
          goal = current_user.budget_goals.find(params[:id])
          goal.destroy!

          render json: { data: nil, meta: {} }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        private

        def authorize_banking_access!
          authorize_feature!(:banking)
        end

        def budget_goal_params
          params.require(:budget_goal).permit(:name, :goal_type, :category_id, :target_amount, :period, :active, :start_date, payment_months: [])
        end

        def serialize_budget_goal(goal, progress = nil)
          data = {
            id: goal.id,
            name: goal.name,
            goal_type: goal.goal_type,
            category_id: goal.category_id,
            category_name: goal.category&.name,
            target_amount: goal.target_amount&.to_f,
            period: goal.period,
            active: goal.active,
            start_date: goal.start_date&.to_s,
            payment_months: goal.payment_months,
            created_at: goal.created_at.iso8601,
            updated_at: goal.updated_at.iso8601
          }

          if progress
            data[:progress] = {
              current_amount: progress.current_amount&.round(2),
              progress_percentage: progress.progress_percentage,
              remaining_amount: progress.remaining_amount&.round(2),
              on_track: progress.on_track,
              period_start: progress.period_start&.to_s,
              period_end: progress.period_end&.to_s,
              days_elapsed: progress.days_elapsed,
              days_remaining: progress.days_remaining
            }
          end

          data
        end
      end
    end
  end
end
