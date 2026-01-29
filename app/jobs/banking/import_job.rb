# frozen_string_literal: true

module Banking
  class ImportJob < ApplicationJob
    queue_as :default

    def perform(user_id, csv_content, bank_account_id: nil)
      user = User.find(user_id)
      bank_account = bank_account_id.present? ? user.bank_accounts.find_by(id: bank_account_id) : nil

      puts "[ImportJob] Starting import for user #{user_id}, CSV size: #{csv_content.bytesize} bytes, account: #{bank_account&.name || 'none'}"
      Rails.logger.info "Banking::ImportJob: Starting import for user #{user_id}, account: #{bank_account&.name || 'none'}"

      result = Banking::ImportService.new(user, csv_content, bank_account: bank_account).call

      if result.success
        puts "[ImportJob] Completed - Total: #{result.total}, Imported: #{result.imported}, Skipped: #{result.skipped}"
        Rails.logger.info "Banking::ImportJob: Import completed - " \
                          "Total: #{result.total}, Imported: #{result.imported}, Skipped: #{result.skipped}"
      else
        puts "[ImportJob] Failed - Errors: #{result.errors.join(', ')}"
        Rails.logger.error "Banking::ImportJob: Import failed - Errors: #{result.errors.join(', ')}"
      end

      broadcast_result(user, result)

      result
    rescue ActiveRecord::RecordNotFound => e
      puts "[ImportJob] User #{user_id} not found: #{e.message}"
      Rails.logger.error "Banking::ImportJob: User #{user_id} not found"
      nil
    rescue StandardError => e
      puts "[ImportJob] ERROR: #{e.class}: #{e.message}"
      puts e.backtrace.first(10).join("\n")
      raise
    end

    private

    def broadcast_result(user, result)
      ActionCable.server.broadcast(
        "banking_import:#{user.id}",
        {
          success: result.success,
          total: result.total,
          imported: result.imported,
          skipped: result.skipped,
          errors: result.errors
        }
      )
      Rails.logger.debug "Banking::ImportJob: Broadcast result to banking_import:#{user.id}"
    rescue StandardError => e
      Rails.logger.error "Banking::ImportJob: Failed to broadcast result: #{e.message}"
    end
  end
end
