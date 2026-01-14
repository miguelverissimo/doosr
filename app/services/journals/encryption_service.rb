# frozen_string_literal: true

require "openssl"

module Journals
  class EncryptionService
    ALGORITHM = "aes-256-gcm"
    PBKDF2_ITERATIONS = 100_000
    KEY_LENGTH = 32
    SALT_LENGTH = 32

    class DecryptionError < StandardError; end

    def self.encrypt(plaintext, key)
      new.encrypt(plaintext, key)
    end

    def self.decrypt(ciphertext, iv, key, auth_tag: nil)
      new.decrypt(ciphertext, iv, key, auth_tag: auth_tag)
    end

    def self.derive_key(password, salt)
      new.derive_key(password, salt)
    end

    def self.generate_salt
      new.generate_salt
    end

    def encrypt(plaintext, key)
      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.encrypt
      cipher.key = key
      iv = cipher.random_iv

      ciphertext = cipher.update(plaintext) + cipher.final
      auth_tag = cipher.auth_tag

      {
        ciphertext: Base64.strict_encode64(ciphertext),
        iv: Base64.strict_encode64(iv),
        auth_tag: Base64.strict_encode64(auth_tag)
      }
    end

    def decrypt(ciphertext, iv, key, auth_tag: nil)
      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.decrypt
      cipher.key = key
      cipher.iv = Base64.strict_decode64(iv)

      if auth_tag
        cipher.auth_tag = Base64.strict_decode64(auth_tag)
      end

      decoded_ciphertext = Base64.strict_decode64(ciphertext)
      result = cipher.update(decoded_ciphertext) + cipher.final
      result.force_encoding("UTF-8")
    rescue OpenSSL::Cipher::CipherError => e
      raise DecryptionError, "Failed to decrypt: #{e.message}"
    end

    def derive_key(password, salt)
      OpenSSL::PKCS5.pbkdf2_hmac(
        password,
        salt,
        PBKDF2_ITERATIONS,
        KEY_LENGTH,
        OpenSSL::Digest::SHA256.new
      )
    end

    def generate_salt
      SecureRandom.hex(SALT_LENGTH)
    end
  end
end
