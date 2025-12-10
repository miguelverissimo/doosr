class DaysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_date, only: [:show, :create, :import]
  before_action :set_day, only: [:close, :reopen]
  layout -> { Views::Layouts::AppLayout.new(pathname: request.path, selected_date: @date, day: @day, latest_importable_day: @latest_importable_day) }

  def show
    # Never auto-creates days - days only created when user explicitly requests
    @day = current_user.days.includes(:imported_from_day, :imported_to_day, :descendant).find_by(date: @date)
    @is_today = @date == Date.today

    # Fetch latest importable day for import button
    @latest_importable_day = Days::FindLatestImportableDayService.new(user: current_user).call

    # Fetch all items recursively if day exists
    if @day
      items_data = Days::FetchItemsService.new(day: @day).call
      @all_items = items_data[:all_items]
      @active_items = items_data[:active_items]
      @inactive_items = items_data[:inactive_items]
    end

    render Views::Days::Show.new(
      day: @day,
      date: @date,
      is_today: @is_today,
      all_items: @all_items,
      active_items: @active_items,
      inactive_items: @inactive_items
    )
  end

  def create
    begin
      @day = Days::OpenDayService.new(user: current_user, date: @date).call
      redirect_to day_path(date: @date), notice: "Day opened successfully"
    rescue ActiveRecord::RecordNotUnique
      redirect_to day_path(date: @date), alert: "Day already exists"
    end
  end

  def close
    if @day.closed?
      redirect_to day_path(date: @day.date), alert: "Day is already closed"
      return
    end

    @day.close!
    redirect_to day_path(date: @day.date), notice: "Day closed successfully"
  end

  def reopen
    if @day.open?
      redirect_to day_path(date: @day.date), alert: "Day is already open"
      return
    end

    @day.reopen!
    redirect_to day_path(date: @day.date), notice: "Day reopened successfully"
  end

  def import
    begin
      result = Days::ImportService.new(user: current_user, target_date: @date).call
      imported_count = result[:imported_count]

      if imported_count > 0
        flash[:toast] = {
          message: "Import complete!",
          description: "Successfully imported #{imported_count} item#{imported_count > 1 ? 's' : ''}",
          type: "success",
          icon: "✅"
        }
      else
        flash[:toast] = {
          message: "Import complete",
          description: "No items to import",
          type: "default",
          icon: "ℹ️"
        }
      end

      redirect_to day_path(date: @date)
    rescue StandardError => e
      Rails.logger.error "Import failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      flash[:toast] = {
        message: "Import failed",
        description: e.message,
        type: "danger",
        icon: "❌"
      }
      redirect_to day_path(date: @date)
    end
  end

  private

  def set_date
    @date = parse_date
  end

  def set_day
    @day = current_user.days.find(params[:id])
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
end
