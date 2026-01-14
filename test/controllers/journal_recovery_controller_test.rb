# frozen_string_literal: true

require "test_helper"

class JournalRecoveryControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true
    )
    @journal_password = "journal_secure_pass"
    @salt = Journals::EncryptionService.generate_salt
    @seed_phrase = Journals::MnemonicService.generate

    # Encrypt seed phrase with password key (not journal encryption key)
    password_key = Journals::EncryptionService.derive_key(@journal_password, @salt)
    encrypted_seed = Journals::EncryptionService.encrypt(@seed_phrase, password_key)

    @user.update!(
      journal_encryption_salt: @salt,
      journal_password_digest: BCrypt::Password.create(@journal_password),
      encrypted_seed_phrase: [ encrypted_seed[:ciphertext], encrypted_seed[:iv], encrypted_seed[:auth_tag] ].join(":"),
      journal_protection_enabled: true
    )
    sign_in @user
  end

  test "new renders recovery form" do
    get new_journal_recovery_path

    assert_response :success
  end

  test "new redirects when protection not enabled" do
    @user.update!(journal_protection_enabled: false, journal_password_digest: nil)

    get new_journal_recovery_path

    assert_redirected_to journals_path
  end

  test "create with valid seed phrase and new password resets password" do
    new_password = "new_secure_pass123"

    post journal_recovery_path, params: {
      seed_phrase: @seed_phrase,
      password: new_password,
      password_confirmation: new_password
    }

    assert_redirected_to journals_path
    @user.reload
    assert BCrypt::Password.new(@user.journal_password_digest) == new_password
  end

  test "create with blank seed phrase returns error" do
    post journal_recovery_path, params: {
      seed_phrase: "",
      password: "new_pass123",
      password_confirmation: "new_pass123"
    }

    assert_response :success
    assert_match(/Seed phrase is required/, response.body)
  end

  test "create with invalid seed phrase format returns error" do
    post journal_recovery_path, params: {
      seed_phrase: "invalid phrase only three words",
      password: "new_pass123",
      password_confirmation: "new_pass123"
    }

    assert_response :success
    assert_match(/Invalid seed phrase/, response.body)
  end

  test "create with blank password returns error" do
    post journal_recovery_path, params: {
      seed_phrase: @seed_phrase,
      password: "",
      password_confirmation: ""
    }

    assert_response :success
    assert_match(/New password is required/, response.body)
  end

  test "create with mismatched passwords returns error" do
    post journal_recovery_path, params: {
      seed_phrase: @seed_phrase,
      password: "new_pass123",
      password_confirmation: "different_pass"
    }

    assert_response :success
    assert_match(/Passwords do not match/, response.body)
  end

  test "create with short password returns error" do
    post journal_recovery_path, params: {
      seed_phrase: @seed_phrase,
      password: "short",
      password_confirmation: "short"
    }

    assert_response :success
    assert_match(/Password must be at least 8 characters/, response.body)
  end

  test "create when protection not enabled redirects" do
    @user.update!(journal_protection_enabled: false, journal_password_digest: nil)

    post journal_recovery_path, params: {
      seed_phrase: @seed_phrase,
      password: "new_pass123",
      password_confirmation: "new_pass123"
    }

    assert_redirected_to journals_path
  end

  test "create re-encrypts seed phrase with new key" do
    new_password = "new_secure_pass123"
    old_encrypted_seed = @user.encrypted_seed_phrase

    post journal_recovery_path, params: {
      seed_phrase: @seed_phrase,
      password: new_password,
      password_confirmation: new_password
    }

    @user.reload
    assert_not_equal old_encrypted_seed, @user.encrypted_seed_phrase

    new_key = Journals::EncryptionService.derive_key(new_password, @user.journal_encryption_salt)
    encrypted_parts = @user.encrypted_seed_phrase.split(":")
    decrypted = Journals::EncryptionService.decrypt(
      encrypted_parts[0],
      encrypted_parts[1],
      new_key,
      auth_tag: encrypted_parts[2]
    )
    assert_equal @seed_phrase, decrypted
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end
