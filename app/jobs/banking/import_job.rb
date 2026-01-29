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
      create_notification(user, result)

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

    def create_notification(user, result)
      now = Time.current
      error_count = result.errors.size

      if result.success
        title = "CSV import complete"
        body = "Imported #{result.imported} transaction#{'s' unless result.imported == 1}"
        body += ", #{result.skipped} skipped" if result.skipped > 0
        body += ", #{error_count} error#{'s' unless error_count == 1}" if error_count > 0
      else
        title = "CSV import failed"
        body = if error_count > 0
          "#{error_count} error#{'s' unless error_count == 1} occurred"
        else
          "Import could not be completed"
        end
        body += " (#{result.imported} imported)" if result.imported > 0
      end

      notification = user.notifications.create!(
        title: title,
        body: body,
        status: "sent",
        sent_at: now,
        remind_at: now,
        channels: [ "in_app" ],
        metadata: { link_path: "/banking" }
      )

      broadcast_badge_update(user)
      deliver_web_push(user, notification)
    rescue StandardError => e
      Rails.logger.error "Banking::ImportJob: Failed to create notification: #{e.message}"
    end

    def broadcast_badge_update(user)
      count = user.unread_notifications_count
      html = ApplicationController.render(
        partial: "notifications/badge_update",
        locals: { count: count }
      )

      ActionCable.server.broadcast("notifications:#{user.id}", { html: html })
    rescue StandardError => e
      Rails.logger.error "Banking::ImportJob: Failed to broadcast badge update: #{e.message}"
    end

    def deliver_web_push(user, notification)
      return unless user.notification_preference(:push_enabled)

      subscriptions = user.push_subscriptions.active
      return if subscriptions.empty?

      base_url = "https://#{ENV.fetch('APP_HOST', 'localhost:3000')}"
      payload = {
        title: notification.title,
        options: {
          body: notification.body,
          icon: "#{base_url}/web-app-manifest-192x192.png",
          badge: "#{base_url}/web-app-manifest-192x192.png",
          data: {
            path: notification.metadata["link_path"] || "/banking",
            notification_id: notification.id,
            timestamp: Time.current.to_i
          },
          tag: "banking-import-#{notification.id}",
          requireInteraction: false
        }
      }

      vapid = {
        subject: ENV.fetch("VAPID_SUBJECT", "mailto:admin@doosr.bfsh.app"),
        public_key: ENV.fetch("VAPID_PUBLIC_KEY"),
        private_key: ENV.fetch("VAPID_PRIVATE_KEY")
      }

      subscriptions.find_each do |sub|
        ::Webpush.payload_send(
          message: JSON.generate(payload),
          endpoint: sub.endpoint,
          p256dh: sub.p256dh_key,
          auth: sub.auth_key,
          vapid: vapid
        )
        sub.touch_last_used!
      rescue StandardError => e
        Rails.logger.error "Banking::ImportJob: Web push failed for subscription #{sub.id}: #{e.message}"
        sub.destroy if e.message.include?("410") || e.message.include?("404") || e.message.include?("Expired")
      end
    rescue StandardError => e
      Rails.logger.error "Banking::ImportJob: Failed to deliver web push: #{e.message}"
    end

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
