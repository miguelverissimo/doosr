# frozen_string_literal: true

module Banking
  class RecurringDetectionJob < ApplicationJob
    queue_as :default

    def perform(user_id)
      user = User.find(user_id)

      Rails.logger.info "Banking::RecurringDetectionJob: Starting detection for user #{user_id}"

      result = Banking::RecurringDetectionService.new(user).call

      if result.success
        Rails.logger.info "Banking::RecurringDetectionJob: Completed - " \
                          "Created: #{result.groups_created}, Updated: #{result.groups_updated}, " \
                          "Linked: #{result.transactions_linked}"
      else
        Rails.logger.error "Banking::RecurringDetectionJob: Failed - Errors: #{result.errors.join(', ')}"
      end

      broadcast_result(user, result)

      result
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "Banking::RecurringDetectionJob: User #{user_id} not found"
      nil
    rescue StandardError => e
      Rails.logger.error "Banking::RecurringDetectionJob: ERROR: #{e.class}: #{e.message}"
      raise
    end

    private

    def broadcast_result(user, result)
      ActionCable.server.broadcast(
        "banking_recurring:#{user.id}",
        {
          success: result.success,
          groups_created: result.groups_created,
          groups_updated: result.groups_updated,
          transactions_linked: result.transactions_linked,
          errors: result.errors
        }
      )
    rescue StandardError => e
      Rails.logger.error "Banking::RecurringDetectionJob: Failed to broadcast result: #{e.message}"
    end
  end
end
