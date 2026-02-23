class ApiToken < ApplicationRecord
  belongs_to :user

  # Available scopes for API access (matches authorize_feature! calls)
  AVAILABLE_SCOPES = %w[day lists notes checklists banking accounting journals agenda].freeze

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true
  validates :token_prefix, presence: true
  validate :scopes_must_be_valid

  attr_accessor :plain_token

  # Returns true if scopes array is non-empty (restricted access)
  def scoped?
    scopes.present?
  end

  # Returns true if token has access to the given scope
  # Empty scopes = full access, otherwise scope must be included
  def has_scope?(scope)
    return true if scopes.blank?

    scopes.include?(scope.to_s)
  end

  def token
    return plain_token if plain_token.present?
    return nil if token_encrypted.blank?

    self.class.decrypt_token(token_encrypted)
  end

  def self.generate_token
    "doo_#{SecureRandom.hex(32)}"
  end

  def self.digest_token(plain)
    Digest::SHA256.hexdigest(plain)
  end

  def self.encrypt_token(plain)
    encryptor.encrypt_and_sign(plain)
  end

  def self.decrypt_token(encrypted)
    encryptor.decrypt_and_verify(encrypted)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  def self.find_by_plain_token(plain)
    return nil if plain.blank?

    find_by(token_digest: digest_token(plain))
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  def self.encryptor
    @encryptor ||= begin
      key = Rails.application.key_generator.generate_key("api_tokens", ActiveSupport::MessageEncryptor.key_len)
      ActiveSupport::MessageEncryptor.new(key)
    end
  end

  private

  def scopes_must_be_valid
    return if scopes.blank?

    invalid_scopes = scopes - AVAILABLE_SCOPES
    if invalid_scopes.any?
      errors.add(:scopes, "contains invalid scopes: #{invalid_scopes.join(', ')}")
    end
  end
end
