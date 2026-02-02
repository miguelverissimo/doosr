module Api
  module V1
    class DaysController < Api::BaseController
      before_action :authorize_day_access!

      resource_description do
        short "Days"
        description "Manage daily task views"
        meta group: "Tasks & Planning"
        formats [ "json" ]
      end

      api :GET, "/days", "Show a day"
      description "Returns the day for a given date (defaults to today) with its items."
      param :date, String, desc: "Date in YYYY-MM-DD format (default: today)", required: false
      def show
        date = parse_date
        day = current_user.days.includes(:descendant).find_by(date: date)

        unless day
          render json: { data: nil, meta: { date: date.to_s } }, status: :ok
          return
        end

        items_data = Days::FetchItemsService.new(day: day).call

        render json: {
          data: serialize_day(day, items_data),
          meta: { date: date.to_s }
        }, status: :ok
      end

      api :POST, "/days", "Create or open a day"
      description "Opens a day for the given date, creating it if it doesn't exist."
      param :date, String, desc: "Date in YYYY-MM-DD format (default: today)", required: false
      def create
        date = parse_date
        result = Days::DayOpeningService.new(user: current_user, date: date).call

        if result[:success]
          day = result[:day]
          items_data = Days::FetchItemsService.new(day: day).call
          status = result[:created] ? :created : :ok

          render json: {
            data: serialize_day(day, items_data),
            meta: { created: result[:created], reopened: result[:reopened] || false }
          }, status: status
        else
          render_error(result[:error], status: :unprocessable_entity)
        end
      end

      api :PATCH, "/days/:id/close", "Close a day"
      description "Closes an open day, preventing further modifications."
      param :id, :number, desc: "Day ID", required: true
      def close
        day = current_user.days.find(params[:id])

        if day.closed?
          render_error("Day is already closed", status: :unprocessable_entity)
          return
        end

        result = Days::CloseService.new(day: day).call

        if result[:success]
          render json: {
            data: serialize_day_basic(day.reload),
            meta: {}
          }, status: :ok
        else
          render_error(result[:error], status: :unprocessable_entity)
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :PATCH, "/days/:id/reopen", "Reopen a day"
      description "Reopens a previously closed day."
      param :id, :number, desc: "Day ID", required: true
      def reopen
        day = current_user.days.find(params[:id])

        if day.open?
          render_error("Day is already open", status: :unprocessable_entity)
          return
        end

        result = Days::ReopenService.new(day: day).call

        if result[:success]
          render json: {
            data: serialize_day_basic(day.reload),
            meta: {}
          }, status: :ok
        else
          render_error(result[:error], status: :unprocessable_entity)
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :POST, "/days/import", "Import items from previous day"
      description "Imports uncompleted items from the most recent importable day into the target date."
      param :date, String, desc: "Target date in YYYY-MM-DD format (default: today)", required: false
      def import
        date = parse_date
        current_day = current_user.days.find_by(date: date)

        if current_day&.closed?
          render_error("Cannot import into a closed day", status: :unprocessable_entity)
          return
        end

        source_day = Days::FindLatestImportableDayService.new(user: current_user, current_date: date).call

        unless source_day
          render_error("No importable days found", status: :unprocessable_entity)
          return
        end

        migration_settings = current_user.day_migration_settings || MigrationOptions.defaults
        result = Days::DayMigrationService.new(
          user: current_user,
          source_day: source_day,
          target_date: date,
          migration_settings: migration_settings
        ).call

        day = current_user.days.find_by(date: date)
        items_data = day ? Days::FetchItemsService.new(day: day).call : nil

        render json: {
          data: day ? serialize_day(day, items_data) : nil,
          meta: { migrated_count: result[:migrated_count] }
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error "API migration failed: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render_error(e.message, status: :unprocessable_entity)
      end

      private

      def authorize_day_access!
        authorize_feature!(:day)
      end

      def parse_date
        if params[:date].present?
          Date.parse(params[:date])
        else
          Date.today
        end
      rescue ArgumentError
        Date.today
      end

      def serialize_day(day, items_data)
        {
          id: day.id,
          date: day.date.to_s,
          state: day.state,
          created_at: day.created_at.iso8601,
          updated_at: day.updated_at.iso8601,
          items: serialize_items(items_data[:active_items] || []),
          inactive_items: serialize_items(items_data[:inactive_items] || [])
        }
      end

      def serialize_day_basic(day)
        {
          id: day.id,
          date: day.date.to_s,
          state: day.state,
          created_at: day.created_at.iso8601,
          updated_at: day.updated_at.iso8601
        }
      end

      def serialize_items(items)
        items.map { |item| serialize_item(item) }
      end

      def serialize_item(item)
        {
          id: item.id,
          title: item.title,
          item_type: item.item_type,
          state: item.state,
          deferred_to: item.deferred_to&.to_s,
          recurrence_rule: item.recurrence_rule,
          created_at: item.created_at.iso8601,
          updated_at: item.updated_at.iso8601
        }
      end
    end
  end
end
