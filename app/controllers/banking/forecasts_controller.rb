# frozen_string_literal: true

module Banking
  class ForecastsController < ApplicationController
    before_action :authenticate_user!
    layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

    def index
      @forecast = ::Banking::ForecastService.new(current_user).call
      @upcoming_expenses = current_user.planned_expenses.upcoming.limit(10)
      @categories = current_user.categories.order(:name)

      respond_to do |format|
        format.html do
          render ::Views::Banking::Forecasts::Index.new(
            user: current_user,
            forecast: @forecast,
            upcoming_expenses: @upcoming_expenses,
            categories: @categories
          )
        end
      end
    end

    def calendar
      @planned_expenses = current_user.planned_expenses
        .includes(:category)
        .where(due_date: Date.current..(Date.current + 12.weeks))
        .order(due_date: :asc)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::Forecasts::CalendarDialog.new(
              planned_expenses: @planned_expenses
            ), layout: false)
          )
        end
      end
    end

    def projections
      @forecast = ::Banking::ForecastService.new(current_user).call

      respond_to do |format|
        format.json do
          render json: {
            current_balance: @forecast.current_balance,
            projections: @forecast.weekly_projections.map do |p|
              {
                week_start: p.week_start.iso8601,
                week_end: p.week_end.iso8601,
                starting_balance: p.starting_balance,
                ending_balance: p.ending_balance,
                recurring_income: p.recurring_income,
                recurring_expenses: p.recurring_expenses,
                planned_expenses: p.planned_expenses,
                variable_spending: p.variable_spending
              }
            end
          }
        end
      end
    end
  end
end
