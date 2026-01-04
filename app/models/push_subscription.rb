# frozen_string_literal: true

class PushSubscription < ApplicationRecord
  belongs_to :user
  has_many :notification_logs, dependent: :nullify

  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true

  scope :for_user, ->(user) { where(user: user) }
  scope :active, -> { where("last_used_at > ?", 30.days.ago).or(where(last_used_at: nil)) }
  scope :stale, -> { where("last_used_at < ?", 30.days.ago) }

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end
end
