# frozen_string_literal: true

class Days::FindLatestImportableDayService
  # Service for finding the latest closed day that can be imported from (global query)
  # Returns: Day or nil
  #
  # Finds most recent closed day that hasn't been imported to another day yet
  # - Filters: state: "closed" and imported_to_day_id is nil
  # - Only returns days BEFORE the current_date (cannot import from same day or future days)
  # - Orders by date descending to get most recent
  # - Returns nil if no importable day found
  # - Returns day with id, date, and state
  # - Can be cached until a day is closed or import completes

  attr_reader :user, :current_date

  def initialize(user:, current_date: Date.today)
    @user = user
    @current_date = current_date
  end

  def call
    # Find CLOSEST previous day that is:
    # 1. Before current_date (date < current_date)
    # 2. Closed (state: closed)
    # 3. Not yet migrated from (imported_to_day_id: nil)
    # Order by date DESC means we get the HIGHEST date first = CLOSEST to target
    user.days
      .where(state: :closed, imported_to_day_id: nil)
      .where("date < ?", current_date)
      .order(date: :desc)
      .select(:id, :user_id, :date, :state, :imported_from_day_id, :imported_at, :imported_to_day_id)
      .first
  end
end
