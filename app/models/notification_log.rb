# frozen_string_literal: true

class NotificationLog < ApplicationRecord
  belongs_to :user
  belongs_to :item, optional: true
  belongs_to :push_subscription, optional: true

  enum :notification_type, {
    scheduled: "scheduled",
    test: "test",
    admin_test: "admin_test"
  }, default: :scheduled, validate: true

  enum :status, {
    pending: "pending",
    sent: "sent",
    failed: "failed"
  }, default: :pending, validate: true

  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :for_user, ->(user) { where(user: user) }
end
