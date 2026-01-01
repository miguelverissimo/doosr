class DaysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_date, only: [ :show, :create, :import ]
  before_action :set_day, only: [ :close, :reopen, :add_permanent_sections ]
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path, selected_date: @date, day: @day, latest_importable_day: @latest_importable_day) }

  def show
    # Never auto-creates days - days only created when user explicitly requests
    @day = current_user.days.includes(:imported_from_day, :imported_to_day, :descendant).find_by(date: @date)
    @is_today = @date == Date.today

    # Fetch latest importable day for import button (only if current day is open)
    @latest_importable_day = Days::FindLatestImportableDayService.new(user: current_user, current_date: @date).call if @day&.open? || @day.nil?

    # Fetch all items and lists recursively if day exists
    if @day
      items_data = Days::FetchItemsService.new(day: @day).call
      @all_items = items_data[:all_items]
      @active_items = items_data[:active_items]
      @inactive_items = items_data[:inactive_items]
      @all_lists = items_data[:all_lists]
      @active_lists = items_data[:active_lists]
      @inactive_lists = items_data[:inactive_lists]
    end

    render ::Views::Days::Show.new(
      day: @day,
      date: @date,
      is_today: @is_today,
      all_items: @all_items,
      active_items: @active_items,
      inactive_items: @inactive_items,
      all_lists: @all_lists,
      active_lists: @active_lists,
      inactive_lists: @inactive_lists
    )
  end

  def create
    result = Days::DayOpeningService.new(user: current_user, date: @date).call

    if result[:success]
      message = if result[:created]
        "Day opened successfully"
      elsif result[:reopened]
        "Day reopened successfully"
      else
        "Day already open"
      end
      redirect_to day_path(date: @date), notice: message
    else
      redirect_to day_path(date: @date), alert: result[:error]
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

  def add_permanent_sections
    result = Days::AddPermanentSectionsService.new(day: @day, user: current_user).call

    if result[:success]
      count = result[:sections_added]
      message = if count.zero?
        "All permanent sections already exist"
      else
        "Added #{count} permanent section#{count > 1 ? 's' : ''}"
      end

      respond_to do |format|
        format.turbo_stream do
          # Reload day and fetch fresh items
          @day.reload
          items_data = Days::FetchItemsService.new(day: @day).call

          # Build tree for rendering
          tree = ItemTree::Build.call(@day.descendant, root_label: "day")
          rendered_items = tree.children.map do |node|
            render_to_string(Views::Items::TreeNode.new(node: node, day: @day))
          end.join

          render turbo_stream: [
            turbo_stream.update("items_list", rendered_items),
            turbo_stream.append("body", "<script>window.toast && window.toast(#{message.to_json}, { type: 'success' })</script>")
          ]
        end
        format.html { redirect_to day_path(date: @day.date), notice: message }
      end
    else
      redirect_to day_path(date: @day.date), alert: result[:error]
    end
  end

  def import
    begin
      # Check if current day is closed - cannot import into closed days
      current_day = current_user.days.find_by(date: @date)
      if current_day&.closed?
        flash[:toast] = {
          message: "Import failed",
          description: "Cannot import into a closed day. Reopen the day first.",
          type: "danger",
          icon: "❌"
        }
        redirect_to day_path(date: @date)
        return
      end

      # Find latest importable day (from days before the current date)
      source_day = Days::FindLatestImportableDayService.new(user: current_user, current_date: @date).call

      unless source_day
        flash[:toast] = {
          message: "Import failed",
          description: "No importable days found",
          type: "danger",
          icon: "❌"
        }
        redirect_to day_path(date: @date)
        return
      end

      # Use user's default migration settings
      migration_settings = current_user.day_migration_settings || MigrationOptions.defaults

      result = Days::DayMigrationService.new(
        user: current_user,
        source_day: source_day,
        target_date: @date,
        migration_settings: migration_settings
      ).call

      migrated_count = result[:migrated_count]

      if migrated_count > 0
        flash[:toast] = {
          message: "Migration complete!",
          description: "Successfully migrated #{migrated_count} item#{migrated_count > 1 ? 's' : ''}",
          type: "success",
          icon: "✅"
        }
      else
        flash[:toast] = {
          message: "Migration complete",
          description: "No items to migrate",
          type: "default",
          icon: "ℹ️"
        }
      end

      redirect_to day_path(date: @date)
    rescue StandardError => e
      Rails.logger.error "Migration failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      flash[:toast] = {
        message: "Migration failed",
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
