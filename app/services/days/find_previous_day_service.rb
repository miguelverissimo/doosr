# frozen_string_literal: true

class Days::FindPreviousDayService
  # Service for finding most recent previous day that can be imported from (relative to a date)
  # Returns: Day or nil
  #
  # Accepts current_date parameter
  # Finds most recent day before current date that hasn't been imported to another day
  # - Filters: date < current_date and imported_to_day_id is nil
  # - Orders by date descending to get most recent
  # - Returns nil if no previous day found
  # - Used for legacy compatibility and date-specific queries

  attr_reader :user, :current_date

  def initialize(user:, current_date:)
    @user = user
    @current_date = current_date.is_a?(Date) ? current_date : Date.parse(current_date.to_s)
  end

  def call
    user.days
        .where("date < ?", current_date)
        .where(imported_to_day_id: nil)
        .order(date: :desc)
        .select(:id, :user_id, :date, :state, :imported_from_day_id, :imported_at, :imported_to_day_id)
        .first
  end
end
