class Ephemery < ApplicationRecord
  validates :start, :end, :aspect, :description, presence: true
  validate :end_after_start

  scope :affecting_date, ->(date) {
    normalized_date = date.to_time.utc.beginning_of_day
    where("start <= ? AND \"end\" >= ?", normalized_date, normalized_date)
      .order(Arel.sql("strongest ASC NULLS LAST"))
  }

  private

  def end_after_start
    return if start.blank? || self.end.blank?

    if self.end < start
      errors.add(:end, "must be after start date")
    end
  end
end
