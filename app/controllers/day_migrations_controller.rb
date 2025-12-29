# frozen_string_literal: true

class DayMigrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_date
  before_action :set_latest_importable_day

  def new
    # Get user's migration settings or use defaults
    @migration_settings = current_user.settings.dig("day_migration_settings") || MigrationOptions.defaults

    # Render the modal as a Turbo Stream
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "day_migration_modal",
          ::Views::Days::MigrationModal.new(
            date: @date,
            latest_importable_day: @latest_importable_day,
            migration_settings: @migration_settings
          )
        )
      end
    end
  end

  def create
    begin
      # Parse migration settings from params
      migration_settings = parse_migration_settings

      # Call migration service with custom settings
      # SOURCE = @latest_importable_day (the day we're importing FROM)
      # TARGET = @date (the day we're viewing/importing TO)
      result = Days::DayMigrationService.new(
        user: current_user,
        source_day: @latest_importable_day,
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

  def set_latest_importable_day
    @latest_importable_day = Days::FindLatestImportableDayService.new(user: current_user, current_date: @date).call

    unless @latest_importable_day
      redirect_to day_path(date: @date), alert: "No importable days found"
    end
  end

  def parse_date
    # CRITICAL: params[:date] MUST be present - this is the day we're viewing (TARGET)
    unless params[:date].present?
      Rails.logger.error "CRITICAL ERROR: No date param provided to migration controller!"
      Rails.logger.error "Params: #{params.inspect}"
      raise ArgumentError, "Date parameter is required for migrations"
    end

    Date.parse(params[:date])
  rescue ArgumentError => e
    Rails.logger.error "CRITICAL ERROR: Invalid date format: #{params[:date]}"
    raise ArgumentError, "Invalid date format: #{params[:date]}"
  end

  def parse_migration_settings
    # Dynamically rebuild settings based on MigrationOptions structure
    # This ensures the entire object is replaced with form data (not merged)
    # Hidden fields send "false" for unchecked, checkboxes send "true" for checked
    settings_params = params[:day_migration_settings]
    return {} unless settings_params.present?

    result = {}

    # Process top-level options
    MigrationOptions.top_level_options.each do |key, _config|
      result[key.to_s] = settings_params[key] == "true"
    end

    # Process nested option groups
    MigrationOptions.nested_option_groups.each do |group_key, _group_config|
      result[group_key.to_s] = {}

      MigrationOptions.options_for_group(group_key).each do |option_key, _option_config|
        result[group_key.to_s][option_key.to_s] = settings_params.dig(group_key, option_key) == "true"
      end
    end

    result
  end
end
