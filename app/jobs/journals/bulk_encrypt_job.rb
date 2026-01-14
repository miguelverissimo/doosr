# frozen_string_literal: true

module Journals
  class BulkEncryptJob < ApplicationJob
    queue_as :default

    def perform(user_id, encryption_key)
      user = User.find(user_id)

      user.journal_fragments.find_each do |fragment|
        next if fragment.encrypted_content.present?
        next if fragment.content.blank?

        result = EncryptionService.encrypt(fragment.content, encryption_key)

        fragment.update_columns(
          encrypted_content: result[:ciphertext],
          content_iv: "#{result[:iv]}:#{result[:auth_tag]}",
          content: nil
        )
      end
    end
  end
end
