# frozen_string_literal: true

module Journals
  class BulkDecryptJob < ApplicationJob
    queue_as :default

    def perform(user_id, encryption_key)
      user = User.find(user_id)

      user.journal_fragments.find_each do |fragment|
        next if fragment.encrypted_content.blank?

        begin
          decrypted = fragment.decrypted_content(encryption_key)

          fragment.update_columns(
            content: decrypted,
            encrypted_content: nil,
            content_iv: nil
          )
        rescue StandardError => e
          Rails.logger.error("Failed to decrypt fragment #{fragment.id}: #{e.message}")
        end
      end
    end
  end
end
