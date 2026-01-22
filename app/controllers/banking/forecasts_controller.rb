# frozen_string_literal: true

module Banking
  class ForecastsController < ApplicationController
    before_action :authenticate_user!
    layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

    def index
      @payment_reminders = current_user.payment_reminders.active.upcoming.includes(:day_payment_reminders)
      @section_spending = ::Banking::SectionSpendingService.new(current_user).call

      # Build a hash of payment_reminder_id => paid_at for quick lookup
      # Uses the already-included day_payment_reminders association to avoid N+1 queries
      @paid_status = @payment_reminders.each_with_object({}) do |reminder, paid_status|
        paid_reminder = reminder.day_payment_reminders
          .select { |dpr| dpr.paid_at.present? }
          .max_by(&:paid_at)
        paid_status[reminder.id] = paid_reminder&.paid_at
      end

      respond_to do |format|
        format.html do
          render ::Views::Banking::Forecasts::Index.new(
            user: current_user,
            payment_reminders: @payment_reminders,
            paid_status: @paid_status,
            section_spending: @section_spending
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

    def other_crap
      @forecast = ::Banking::ForecastService.new(current_user).call

      respond_to do |format|
        format.html do
          render ::Views::Banking::Forecasts::OtherCrap.new(
            user: current_user,
            forecast: @forecast
          )
        end
      end
    end
  end
end
