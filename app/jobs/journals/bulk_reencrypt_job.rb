# frozen_string_literal: true

module Journals
  class BulkReencryptJob < ApplicationJob
    queue_as :default

    def perform(user_id, old_key, new_key)
      user = User.find(user_id)

      user.journal_fragments.find_each do |fragment|
        next if fragment.encrypted_content.blank?

        begin
          plaintext = fragment.decrypted_content(old_key)

          result = EncryptionService.encrypt(plaintext, new_key)

          fragment.update_columns(
            encrypted_content: result[:ciphertext],
            content_iv: "#{result[:iv]}:#{result[:auth_tag]}"
          )
        rescue StandardError => e
          Rails.logger.error "BulkReencryptJob: Failed to re-encrypt fragment #{fragment.id}: #{e.message}"
        end
      end
    end
  end
end
