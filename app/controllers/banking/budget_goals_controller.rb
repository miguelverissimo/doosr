# frozen_string_literal: true

module Banking
  class BudgetGoalsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_budget_goal, only: [ :edit, :update, :destroy ]
    layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

    def index
      @budget_goals = current_user.budget_goals.includes(:category).order(:goal_type, :created_at)
      @categories = current_user.categories.order(:name)

      respond_to do |format|
        format.html { redirect_to banking_forecasts_path }
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::Goals::IndexDialog.new(
              budget_goals: @budget_goals,
              categories: @categories
            ), layout: false)
          )
        end
      end
    end

    def new
      @budget_goal = current_user.budget_goals.build
      @categories = current_user.categories.order(:name)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::Goals::FormDialog.new(
              budget_goal: @budget_goal,
              categories: @categories
            ), layout: false)
          )
        end
      end
    end

    def create
      @budget_goal = current_user.budget_goals.build(budget_goal_params)

      if @budget_goal.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.remove("budget_goal_form_dialog")
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "budget_goal_form_errors",
              "<div class='text-sm text-destructive'>#{@budget_goal.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def edit
      @categories = current_user.categories.order(:name)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::Goals::FormDialog.new(
              budget_goal: @budget_goal,
              categories: @categories
            ), layout: false)
          )
        end
      end
    end

    def update
      if @budget_goal.update(budget_goal_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.remove("budget_goal_form_dialog")
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "budget_goal_form_errors",
              "<div class='text-sm text-destructive'>#{@budget_goal.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def destroy
      @budget_goal.destroy!

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.remove("budget_goal_#{@budget_goal.id}")
        end
      end
    end

    private

    def set_budget_goal
      @budget_goal = current_user.budget_goals.find(params[:id])
    end

    def budget_goal_params
      params.require(:budget_goal).permit(:name, :goal_type, :category_id, :target_amount, :period, :active, :start_date, payment_months: [])
    end
  end
end
