# frozen_string_literal: true

require "test_helper"

class JournalFragmentTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123")
    @journal = @user.journals.create!(date: Date.current)
    @fragment = @journal.journal_fragments.create!(
      user: @user,
      content: "Test content"
    )
  end

  test "decrypted_content returns plain content when not encrypted" do
    assert_not @fragment.encrypted?
    assert_equal "Test content", @fragment.decrypted_content(nil)
    assert_equal "Test content", @fragment.decrypted_content("any_key")
  end

  test "decrypted_content decrypts encrypted content with key" do
    salt = Journals::EncryptionService.generate_salt
    key = Journals::EncryptionService.derive_key("password123", salt)

    result = Journals::EncryptionService.encrypt("Secret journal entry", key)
    @fragment.update!(
      encrypted_content: result[:ciphertext],
      content_iv: "#{result[:iv]}:#{result[:auth_tag]}",
      content: nil
    )

    assert @fragment.encrypted?
    assert_equal "Secret journal entry", @fragment.decrypted_content(key)
  end

  test "decrypted_content raises error when key is nil for encrypted content" do
    @fragment.update!(
      encrypted_content: "encrypted_data",
      content_iv: "iv:auth_tag",
      content: nil
    )

    assert @fragment.encrypted?
    assert_raises(ArgumentError) { @fragment.decrypted_content(nil) }
  end

  test "encrypted? returns true when encrypted_content present" do
    assert_not @fragment.encrypted?

    @fragment.update!(encrypted_content: "encrypted_data", content_iv: "iv:tag", content: nil)
    assert @fragment.encrypted?
  end

  test "displayable_content returns plain content when not encrypted" do
    Current.encryption_key = nil
    assert_equal "Test content", @fragment.displayable_content
  end

  test "displayable_content returns decrypted content when encryption key available" do
    salt = Journals::EncryptionService.generate_salt
    key = Journals::EncryptionService.derive_key("password123", salt)

    result = Journals::EncryptionService.encrypt("Secret journal entry", key)
    @fragment.update!(
      encrypted_content: result[:ciphertext],
      content_iv: "#{result[:iv]}:#{result[:auth_tag]}",
      content: nil
    )

    Current.encryption_key = key
    assert_equal "Secret journal entry", @fragment.displayable_content
  ensure
    Current.reset
  end

  test "displayable_content returns placeholder when encrypted but no key" do
    @fragment.update!(encrypted_content: "encrypted_data", content_iv: "iv:tag", content: nil)

    Current.encryption_key = nil
    assert_equal "[Encrypted content]", @fragment.displayable_content
  end

  test "content_preview uses displayable_content" do
    salt = Journals::EncryptionService.generate_salt
    key = Journals::EncryptionService.derive_key("password123", salt)

    result = Journals::EncryptionService.encrypt("This is a secret entry", key)
    @fragment.update!(
      encrypted_content: result[:ciphertext],
      content_iv: "#{result[:iv]}:#{result[:auth_tag]}",
      content: nil
    )

    Current.encryption_key = key
    assert_equal "This is a secret entry", @fragment.content_preview
  ensure
    Current.reset
  end

  test "rendered_markdown uses displayable_content" do
    salt = Journals::EncryptionService.generate_salt
    key = Journals::EncryptionService.derive_key("password123", salt)

    result = Journals::EncryptionService.encrypt("**Bold** content", key)
    @fragment.update!(
      encrypted_content: result[:ciphertext],
      content_iv: "#{result[:iv]}:#{result[:auth_tag]}",
      content: nil
    )

    Current.encryption_key = key
    assert_includes @fragment.rendered_markdown, "<strong>Bold</strong>"
  ensure
    Current.reset
  end

  test "encrypts content on save when user has protection enabled and encryption key available" do
    salt = Journals::EncryptionService.generate_salt
    key = Journals::EncryptionService.derive_key("password123", salt)

    @user.update!(
      journal_protection_enabled: true,
      journal_password_digest: BCrypt::Password.create("password123"),
      journal_encryption_salt: salt
    )

    Current.encryption_key = key

    fragment = @journal.journal_fragments.create!(
      user: @user,
      content: "Secret entry to encrypt"
    )

    assert fragment.encrypted?
    assert_nil fragment.content
    assert fragment.encrypted_content.present?
    assert fragment.content_iv.present?
    assert_equal "Secret entry to encrypt", fragment.decrypted_content(key)
  ensure
    Current.reset
  end

  test "does not encrypt content when user has protection disabled" do
    @user.update!(journal_protection_enabled: false)

    salt = Journals::EncryptionService.generate_salt
    key = Journals::EncryptionService.derive_key("password123", salt)
    Current.encryption_key = key

    fragment = @journal.journal_fragments.create!(
      user: @user,
      content: "Plain content"
    )

    assert_not fragment.encrypted?
    assert_equal "Plain content", fragment.content
    assert_nil fragment.encrypted_content
  ensure
    Current.reset
  end

  test "does not encrypt content when encryption key not available" do
    @user.update!(
      journal_protection_enabled: true,
      journal_password_digest: BCrypt::Password.create("password123")
    )

    Current.encryption_key = nil

    fragment = @journal.journal_fragments.create!(
      user: @user,
      content: "Unprotected entry"
    )

    assert_not fragment.encrypted?
    assert_equal "Unprotected entry", fragment.content
  ensure
    Current.reset
  end

  test "re-encrypts content on update when user has protection enabled" do
    salt = Journals::EncryptionService.generate_salt
    key = Journals::EncryptionService.derive_key("password123", salt)

    @user.update!(
      journal_protection_enabled: true,
      journal_password_digest: BCrypt::Password.create("password123"),
      journal_encryption_salt: salt
    )

    result = Journals::EncryptionService.encrypt("Original secret", key)
    @fragment.update!(
      encrypted_content: result[:ciphertext],
      content_iv: "#{result[:iv]}:#{result[:auth_tag]}",
      content: nil
    )

    Current.encryption_key = key

    @fragment.content = "Updated secret"
    @fragment.save!

    assert @fragment.encrypted?
    assert_nil @fragment.content
    assert_equal "Updated secret", @fragment.decrypted_content(key)
  ensure
    Current.reset
  end
end
