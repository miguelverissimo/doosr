# frozen_string_literal: true

class Days::DayOpeningService
  # Unified service for creating new days or reopening closed days
  #
  # Behavior:
  # - If day doesn't exist: Creates new day + descendant + permanent sections
  # - If day exists and is closed: Reopens day (state change ONLY, no sections)
  # - If day exists and is open: Returns existing day
  #
  # Returns: { success: Boolean, day: Day, created: Boolean, reopened: Boolean, error: String }

  attr_reader :user, :date

  def initialize(user:, date:)
    @user = user
    @date = date.is_a?(Date) ? date : Date.parse(date.to_s)
  end

  def call
    ActiveRecord::Base.transaction do
      existing_day = user.days.find_by(date: date)

      if existing_day
        # Day exists - reopen if closed, otherwise return as-is
        if existing_day.closed?
          existing_day.reopen!
          return { success: true, day: existing_day, created: false, reopened: true }
        else
          return { success: true, day: existing_day, created: false, reopened: false }
        end
      end

      # Create new day with permanent sections
      day = create_new_day_with_sections
      { success: true, day: day, created: true, reopened: false }
    end
  rescue StandardError => e
    Rails.logger.error "Day opening failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { success: false, error: e.message }
  end

  private

  def create_new_day_with_sections
    # Create day (triggers after_create callback that creates descendant)
    # Skip the permanent_sections callback since we'll handle it below
    day = user.days.create!(date: date, state: :open, skip_permanent_sections_callback: true)

    # Descendant is created automatically by after_create callback
    # Now add permanent sections using consolidated service
    Days::AddPermanentSectionsService.new(day: day, user: user).call

    day
  end
end
