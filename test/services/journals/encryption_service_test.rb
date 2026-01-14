# frozen_string_literal: true

require "test_helper"

class Journals::EncryptionServiceTest < ActiveSupport::TestCase
  def setup
    @service = Journals::EncryptionService.new
    @password = "test_password_123"
    @salt = @service.generate_salt
    @key = @service.derive_key(@password, @salt)
  end

  test "encrypt returns ciphertext, iv, and auth_tag" do
    plaintext = "Hello, World!"

    result = @service.encrypt(plaintext, @key)

    assert result.key?(:ciphertext)
    assert result.key?(:iv)
    assert result.key?(:auth_tag)
    assert_not_equal plaintext, result[:ciphertext]
  end

  test "decrypt returns original plaintext" do
    plaintext = "Hello, World!"

    encrypted = @service.encrypt(plaintext, @key)
    decrypted = @service.decrypt(
      encrypted[:ciphertext],
      encrypted[:iv],
      @key,
      auth_tag: encrypted[:auth_tag]
    )

    assert_equal plaintext, decrypted
  end

  test "encrypt/decrypt round-trip with unicode content" do
    plaintext = "Hello, 世界! 🔐 Привет мир!"

    encrypted = @service.encrypt(plaintext, @key)
    decrypted = @service.decrypt(
      encrypted[:ciphertext],
      encrypted[:iv],
      @key,
      auth_tag: encrypted[:auth_tag]
    )

    assert_equal plaintext, decrypted
  end

  test "encrypt/decrypt round-trip with long content" do
    plaintext = "A" * 10_000

    encrypted = @service.encrypt(plaintext, @key)
    decrypted = @service.decrypt(
      encrypted[:ciphertext],
      encrypted[:iv],
      @key,
      auth_tag: encrypted[:auth_tag]
    )

    assert_equal plaintext, decrypted
  end

  test "decrypt with wrong key raises DecryptionError" do
    plaintext = "Secret message"
    encrypted = @service.encrypt(plaintext, @key)

    wrong_key = @service.derive_key("wrong_password", @salt)

    assert_raises(Journals::EncryptionService::DecryptionError) do
      @service.decrypt(
        encrypted[:ciphertext],
        encrypted[:iv],
        wrong_key,
        auth_tag: encrypted[:auth_tag]
      )
    end
  end

  test "decrypt with tampered ciphertext raises DecryptionError" do
    plaintext = "Secret message"
    encrypted = @service.encrypt(plaintext, @key)

    tampered_ciphertext = Base64.strict_encode64("tampered_data")

    assert_raises(Journals::EncryptionService::DecryptionError) do
      @service.decrypt(
        tampered_ciphertext,
        encrypted[:iv],
        @key,
        auth_tag: encrypted[:auth_tag]
      )
    end
  end

  test "derive_key produces consistent key for same password and salt" do
    key1 = @service.derive_key(@password, @salt)
    key2 = @service.derive_key(@password, @salt)

    assert_equal key1, key2
  end

  test "derive_key produces different keys for different passwords" do
    key1 = @service.derive_key("password1", @salt)
    key2 = @service.derive_key("password2", @salt)

    assert_not_equal key1, key2
  end

  test "derive_key produces different keys for different salts" do
    salt1 = @service.generate_salt
    salt2 = @service.generate_salt

    key1 = @service.derive_key(@password, salt1)
    key2 = @service.derive_key(@password, salt2)

    assert_not_equal key1, key2
  end

  test "generate_salt produces unique values" do
    salt1 = @service.generate_salt
    salt2 = @service.generate_salt

    assert_not_equal salt1, salt2
  end

  test "generate_salt produces hex string of expected length" do
    salt = @service.generate_salt

    assert salt.is_a?(String)
    assert_equal 64, salt.length
    assert_match(/\A[0-9a-f]+\z/, salt)
  end

  test "class methods work as expected" do
    plaintext = "Hello via class methods"
    salt = Journals::EncryptionService.generate_salt
    key = Journals::EncryptionService.derive_key(@password, salt)
    encrypted = Journals::EncryptionService.encrypt(plaintext, key)
    decrypted = Journals::EncryptionService.decrypt(
      encrypted[:ciphertext],
      encrypted[:iv],
      key,
      auth_tag: encrypted[:auth_tag]
    )

    assert_equal plaintext, decrypted
  end

  test "derived key length is 32 bytes (256 bits)" do
    key = @service.derive_key(@password, @salt)

    assert_equal 32, key.bytesize
  end
end
