# frozen_string_literal: true

class Notification < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :item

  # Valid statuses and channels
  VALID_STATUSES = %w[pending sent read dismissed].freeze
  VALID_CHANNELS = %w[push in_app].freeze

  # Validations
  validates :user_id, presence: true
  validates :item_id, presence: true
  validates :remind_at, presence: true
  validates :status, inclusion: { in: VALID_STATUSES }
  validate :remind_at_must_be_future, on: :create
  validate :channels_must_be_valid

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :due, -> { pending.where("remind_at <= ?", Time.current) }
  scope :unread, -> { where(status: "sent").where(read_at: nil) }
  scope :for_user, ->(user) { where(user: user) }

  # Status transition methods (idempotent)
  def mark_sent!
    return if status == "sent"

    update!(status: "sent", sent_at: Time.current)
  end

  def mark_read!
    return if status == "read"

    update!(status: "read", read_at: Time.current)
  end

  def mark_dismissed!
    return if status == "dismissed"

    update!(status: "dismissed")
  end

  def cancel!
    destroy if status == "pending"
  end

  private

  def remind_at_must_be_future
    return if remind_at.blank?

    if remind_at <= Time.current
      errors.add(:remind_at, "must be in the future")
    end
  end

  def channels_must_be_valid
    return if channels.blank?

    invalid_channels = channels - VALID_CHANNELS
    if invalid_channels.any?
      errors.add(:channels, "contains invalid values: #{invalid_channels.join(', ')}")
    end
  end
end
