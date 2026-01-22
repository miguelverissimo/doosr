# frozen_string_literal: true

# DayPaymentReminder represents a payment reminder instance on a specific day.
# These are stored in descendants as {"DayPaymentReminder" => id} tuples.
# Similar to how notes work, but for payment reminders.
#
class DayPaymentReminder < ApplicationRecord
  belongs_to :user
  belongs_to :payment_reminder

  validates :reminder_date, presence: true
  validates :days_until_cutoff, presence: true
  validates :user_id, uniqueness: { scope: [:payment_reminder_id, :reminder_date], message: "already has this payment reminder for this date" }

  # Find all descendants containing this day payment reminder
  def parent_descendants
    tuple = { "DayPaymentReminder" => id }
    Descendant.where(
      "active_items @> ? OR inactive_items @> ?",
      [tuple].to_json,
      [tuple].to_json
    )
  end

  # Get all parent contexts (days, items, etc.)
  def parent_contexts
    parent_descendants.includes(:descendable).map do |descendant|
      {
        type: descendant.descendable_type,
        object: descendant.descendable
      }
    end
  end

  def cutoff_date
    payment_reminder.cutoff_date
  end

  def title
    payment_reminder.title
  end

  def payment_url
    payment_reminder.payment_url
  end

  def expected_amount
    payment_reminder.expected_amount
  end

  def overdue?
    cutoff_date < Date.current
  end

  def due_today?
    cutoff_date == Date.current
  end

  def due_soon?
    days_until_cutoff <= 3 && !overdue?
  end

  def paid?
    paid_at.present?
  end

  def mark_paid!
    update!(paid_at: Time.current)
    # Move to inactive_items in all parent descendants
    parent_descendants.each do |descendant|
      descendant.deactivate_record("DayPaymentReminder", id)
      descendant.save!
    end
    # Set the parent PaymentReminder to inactive
    payment_reminder.update!(active: false)
  end
end
