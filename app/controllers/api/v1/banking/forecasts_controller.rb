# frozen_string_literal: true

module Api
  module V1
    module Banking
      class ForecastsController < Api::BaseController
        before_action :authorize_banking_access!

        resource_description do
          short "Forecasts"
          description "View financial forecasts and projections"
          meta group: "Banking"
          formats [ "json" ]
        end

        api :GET, "/banking/forecasts", "Get forecast overview"
        description "Returns payment reminders with paid status and section spending."
        def index
          payment_reminders = current_user.payment_reminders.active.upcoming.includes(:day_payment_reminders)
          section_spending = ::Banking::SectionSpendingService.new(current_user).call

          paid_status = payment_reminders.each_with_object({}) do |reminder, status|
            paid_reminder = reminder.day_payment_reminders
              .select { |dpr| dpr.paid_at.present? }
              .max_by(&:paid_at)
            status[reminder.id] = paid_reminder&.paid_at
          end

          render json: {
            data: {
              payment_reminders: payment_reminders.map { |r| serialize_reminder_with_status(r, paid_status[r.id]) },
              section_spending: section_spending.map { |s| serialize_section_spending(s) }
            },
            meta: {}
          }, status: :ok
        end

        api :GET, "/banking/forecasts/calendar", "Get expense calendar"
        description "Returns planned expenses for the next 12 weeks."
        def calendar
          planned_expenses = current_user.planned_expenses
            .includes(:category)
            .where(due_date: Date.current..(Date.current + 12.weeks))
            .order(due_date: :asc)

          render json: {
            data: planned_expenses.map { |e| serialize_calendar_expense(e) },
            meta: {
              start_date: Date.current.to_s,
              end_date: (Date.current + 12.weeks).to_s,
              total_count: planned_expenses.count
            }
          }, status: :ok
        end

        api :GET, "/banking/forecasts/projections", "Get cash flow projections"
        description "Returns 12-week cash flow projections."
        def projections
          forecast = ::Banking::ForecastService.new(current_user).call

          render json: {
            data: {
              current_balance: forecast.current_balance,
              projections: forecast.weekly_projections.map { |p| serialize_projection(p) },
              warnings: forecast.warnings.map { |w| serialize_warning(w) }
            },
            meta: {}
          }, status: :ok
        end

        private

        def authorize_banking_access!
          authorize_feature!(:banking)
        end

        def serialize_reminder_with_status(reminder, paid_at)
          {
            id: reminder.id,
            title: reminder.title,
            expected_amount: reminder.expected_amount&.to_f,
            cutoff_date: reminder.cutoff_date&.to_s,
            payment_url: reminder.payment_url,
            active: reminder.active,
            paid_at: paid_at&.iso8601
          }
        end

        def serialize_section_spending(spending)
          {
            section_name: spending.section.name,
            section_color: spending.section.color,
            spent_this_month: spending.spent_this_month.round(2),
            limit: spending.limit.round(2),
            progress_percentage: spending.progress_percentage,
            remaining: spending.remaining.round(2),
            over_limit: spending.over_limit,
            subcategories_count: spending.subcategories_count
          }
        end

        def serialize_calendar_expense(expense)
          {
            id: expense.id,
            description: expense.description,
            expected_amount: expense.expected_amount&.to_f,
            due_date: expense.due_date&.to_s,
            completed: expense.completed,
            category_name: expense.category&.name,
            category_color: expense.category&.color
          }
        end

        def serialize_projection(projection)
          {
            week_start: projection.week_start.iso8601,
            week_end: projection.week_end.iso8601,
            starting_balance: projection.starting_balance,
            ending_balance: projection.ending_balance,
            recurring_income: projection.recurring_income,
            recurring_expenses: projection.recurring_expenses,
            planned_expenses: projection.planned_expenses,
            variable_spending: projection.variable_spending
          }
        end

        def serialize_warning(warning)
          {
            type: warning.type,
            message: warning.message,
            week: warning.week.iso8601,
            amount: warning.amount
          }
        end
      end
    end
  end
end
