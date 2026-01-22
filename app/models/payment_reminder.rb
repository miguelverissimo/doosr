# frozen_string_literal: true

class PaymentReminder < ApplicationRecord
  belongs_to :user

  before_validation :normalize_reminder_days_before

  validates :title, presence: true
  validates :cutoff_date, presence: true
  validates :reminder_days_before, presence: true
  validate :reminder_days_before_must_be_valid_array

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :upcoming, -> { active.where("cutoff_date >= ?", Date.current).order(cutoff_date: :asc) }

  # Returns reminders that should trigger on a given date
  scope :due_on, ->(date) {
    active.where("cutoff_date >= ?", date).select do |reminder|
      reminder.reminder_days_before.any? do |days_before|
        (reminder.cutoff_date - days_before.days) == date
      end
    end
  }

  def reminder_dates
    reminder_days_before.map { |days| cutoff_date - days.days }.sort
  end

  def should_remind_on?(date)
    reminder_days_before.any? { |days| (cutoff_date - days.days) == date }
  end

  def days_until_cutoff(from_date = Date.current)
    (cutoff_date - from_date).to_i
  end

  def reminder_item_exists_for_date?(date)
    Item.where(user: user)
        .where("extra_data->>'payment_reminder_id' = ?", id.to_s)
        .where("extra_data->>'reminder_date' = ?", date.to_s)
        .exists?
  end

  def overdue?
    cutoff_date < Date.current
  end

  def due_today?
    cutoff_date == Date.current
  end

  # Debug method to check if reminder should trigger on a given date
  def debug_should_remind_on?(date)
    {
      reminder_id: id,
      active: active?,
      cutoff_date: cutoff_date,
      reminder_days_before: reminder_days_before,
      check_date: date,
      reminder_dates: reminder_dates,
      should_remind: should_remind_on?(date),
      calculation: reminder_days_before.map { |days| "#{cutoff_date} - #{days} days = #{cutoff_date - days.days} (== #{date}? #{cutoff_date - days.days == date})" }
    }
  end

  private

  def normalize_reminder_days_before
    return unless reminder_days_before.is_a?(Array)

    self.reminder_days_before = reminder_days_before
      .reject(&:blank?)
      .map(&:to_i)
      .uniq
      .sort
      .reverse
  end

  def reminder_days_before_must_be_valid_array
    unless reminder_days_before.is_a?(Array)
      errors.add(:reminder_days_before, "must be an array")
      return
    end

    unless reminder_days_before.all? { |d| d.is_a?(Integer) && d >= 0 }
      errors.add(:reminder_days_before, "must contain only non-negative integers")
    end

    if reminder_days_before.empty?
      errors.add(:reminder_days_before, "must have at least one value")
    end
  end
end
