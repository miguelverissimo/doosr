# frozen_string_literal: true

class Days::ValidateImportConditionsService
  # Service for validating that import can proceed
  # Returns: { valid: Boolean, error_message: String }
  #
  # Checks:
  # - Source day exists and is closed
  # - Source day is before target date
  # - Target day hasn't already been imported from another day
  # - Target date is not in the future

  attr_reader :user, :source_day, :target_date

  def initialize(user:, source_day:, target_date:)
    @user = user
    @source_day = source_day
    @target_date = target_date.is_a?(Date) ? target_date : Date.parse(target_date.to_s)
  end

  def call
    # Check source day exists
    unless source_day
      return { valid: false, error_message: "No closed day available to import from" }
    end

    # Check source day is closed
    unless source_day.closed?
      return { valid: false, error_message: "Source day must be closed before importing" }
    end

    # Check source day is before target date
    unless source_day.date < target_date
      return { valid: false, error_message: "Cannot import from a day that is not before the target date" }
    end

    # Check target date is not in the future
    if target_date > Date.today
      return { valid: false, error_message: "Cannot import to a future date" }
    end

    # Check if target day already exists and has been imported from another day
    target_day = user.days.find_by(date: target_date)
    if target_day&.imported_from_day_id.present?
      return { valid: false, error_message: "Target day has already been imported from another day" }
    end

    { valid: true, error_message: nil }
  end
end
