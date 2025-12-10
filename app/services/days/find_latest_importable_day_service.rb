# frozen_string_literal: true

class Days::FindLatestImportableDayService
  # Service for finding the latest closed day that can be imported from (global query)
  # Returns: Day or nil
  #
  # Finds most recent closed day that hasn't been imported to another day yet
  # - Filters: state: "closed" and imported_to_day_id is nil
  # - Orders by date descending to get most recent
  # - Returns nil if no importable day found
  # - Returns day with id, date, and state
  # - Can be cached until a day is closed or import completes

  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def call
    user.days
        .where(state: :closed, imported_to_day_id: nil)
        .order(date: :desc)
        .select(:id, :user_id, :date, :state, :imported_from_day_id, :imported_at, :imported_to_day_id)
        .first
  end
end
