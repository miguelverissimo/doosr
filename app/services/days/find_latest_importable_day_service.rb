# frozen_string_literal: true

class Days::FindLatestImportableDayService
  # Service for finding the latest closed day that can be imported from
  # Returns: Day or nil
  #
  # Finds the most recent closed day before current_date.
  # A day can be imported from multiple times - the migration service
  # handles preventing duplicate imports.

  attr_reader :user, :current_date

  def initialize(user:, current_date: Date.today)
    @user = user
    @current_date = current_date
  end

  def call
    user.days
      .where(state: :closed)
      .where("date < ?", current_date)
      .order(date: :desc)
      .select(:id, :user_id, :date, :state, :imported_from_day_id, :imported_at, :imported_to_day_id)
      .first
  end
end
