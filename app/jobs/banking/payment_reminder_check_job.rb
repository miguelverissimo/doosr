# frozen_string_literal: true

module Banking
  class PaymentReminderCheckJob < ApplicationJob
    queue_as :default

    def perform
      Rails.logger.info "PaymentReminderCheckJob: Starting daily check"

      users_with_active_reminders.each do |user|
        process_user_reminders(user)
      end

      Rails.logger.info "PaymentReminderCheckJob: Completed daily check"
    end

    private

    def users_with_active_reminders
      User.joins(:payment_reminders)
          .where(payment_reminders: { active: true })
          .distinct
    end

    def process_user_reminders(user)
      result = Banking::PaymentReminderProcessorService.new(user).call

      if result.success
        Rails.logger.info "PaymentReminderCheckJob: User #{user.id} - " \
                          "Created: #{result.items_created}, Skipped: #{result.skipped_count}"
      else
        Rails.logger.error "PaymentReminderCheckJob: User #{user.id} failed - " \
                           "Errors: #{result.errors.join(', ')}"
      end
    rescue StandardError => e
      Rails.logger.error "PaymentReminderCheckJob: User #{user.id} error - #{e.message}"
    end
  end
end
