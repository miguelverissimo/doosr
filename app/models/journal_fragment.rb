# frozen_string_literal: true

class JournalFragment < ApplicationRecord
  belongs_to :user
  belongs_to :journal

  validates :user, presence: true
  validates :journal, presence: true
  validates :content, presence: true, unless: :encrypted?

  before_save :encrypt_content_if_protected

  def encrypted?
    encrypted_content.present?
  end

  def decrypted_content(key)
    return content unless encrypted?

    raise ArgumentError, "Encryption key required for encrypted content" if key.nil?

    iv, auth_tag = content_iv.split(":")
    Journals::EncryptionService.decrypt(encrypted_content, iv, key, auth_tag: auth_tag)
  end

  def parent_descendants
    tuple = { "JournalFragment" => id }
    ::Descendant.where(
      "active_items @> ? OR inactive_items @> ?",
      [ tuple ].to_json,
      [ tuple ].to_json
    )
  end

  def content_preview
    displayable_content.truncate(100)
  end

  def rendered_markdown
    ApplicationController.helpers.render_markdown(displayable_content)
  end

  def displayable_content
    if encrypted? && Current.encryption_key.present?
      decrypted_content(Current.encryption_key)
    elsif encrypted?
      "[Encrypted content]"
    else
      content
    end
  end

  private

  def encrypt_content_if_protected
    return unless user&.journal_protection_enabled?
    return unless Current.encryption_key.present?
    return unless content.present?

    result = Journals::EncryptionService.encrypt(content, Current.encryption_key)
    self.encrypted_content = result[:ciphertext]
    self.content_iv = "#{result[:iv]}:#{result[:auth_tag]}"
    self.content = nil
  end
end
