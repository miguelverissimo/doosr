# frozen_string_literal: true

class JournalPromptTemplate < ApplicationRecord
  belongs_to :user

  validates :prompt_text, presence: true
  validates :user, presence: true
  validate :schedule_rule_is_valid_json

  scope :for_user, ->(user) { where(user: user) }
  scope :active, -> { where(active: true) }

  def scheduled_for_date?(date)
    return false unless active?
    return false if schedule_rule.blank?

    ::Journals::ScheduleCalculator.call(schedule_rule, date)
  end

  def active?
    active
  end

  private

  def schedule_rule_is_valid_json
    return if schedule_rule.blank?

    unless schedule_rule.is_a?(Hash)
      errors.add(:schedule_rule, "must be a valid JSON object")
      return
    end

    frequency = schedule_rule["frequency"]
    return if frequency.blank?

    valid_frequencies = %w[
      daily
      weekly_start
      weekly_end
      monthly_start
      monthly_end
      day_of_month
      every_n_days
      specific_weekdays
    ]

    unless valid_frequencies.include?(frequency)
      errors.add(:schedule_rule, "has invalid frequency: #{frequency}")
    end
  end
end
