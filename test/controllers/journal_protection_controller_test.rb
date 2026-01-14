# frozen_string_literal: true

require "test_helper"

class JournalProtectionControllerTest < ActionDispatch::IntegrationTest
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

  test "update with valid current password and new password changes password" do
    new_password = "new_secure_pass123"

    patch journal_protection_settings_path, params: {
      current_password: @journal_password,
      new_password: new_password,
      new_password_confirmation: new_password
    }, as: :turbo_stream


    assert_response :success
    @user.reload
    assert BCrypt::Password.new(@user.journal_password_digest) == new_password
  end

  test "update with incorrect current password returns error" do
    patch journal_protection_settings_path, params: {
      current_password: "wrong_password",
      new_password: "new_pass123",
      new_password_confirmation: "new_pass123"
    }, as: :turbo_stream

    assert_response :success
    assert_includes response.body, "Current password is incorrect"
    @user.reload
    assert BCrypt::Password.new(@user.journal_password_digest) == @journal_password
  end

  test "update with blank current password returns error" do
    patch journal_protection_settings_path, params: {
      current_password: "",
      new_password: "new_pass123",
      new_password_confirmation: "new_pass123"
    }, as: :turbo_stream

    assert_response :success
    assert_includes response.body, "Current password is required"
  end

  test "update with blank new password returns error" do
    patch journal_protection_settings_path, params: {
      current_password: @journal_password,
      new_password: "",
      new_password_confirmation: ""
    }, as: :turbo_stream

    assert_response :success
    assert_includes response.body, "New password is required"
  end

  test "update with mismatched new passwords returns error" do
    patch journal_protection_settings_path, params: {
      current_password: @journal_password,
      new_password: "new_pass123",
      new_password_confirmation: "different_pass"
    }, as: :turbo_stream

    assert_response :success
    assert_includes response.body, "New passwords do not match"
  end

  test "update with short new password returns error" do
    patch journal_protection_settings_path, params: {
      current_password: @journal_password,
      new_password: "short",
      new_password_confirmation: "short"
    }, as: :turbo_stream

    assert_response :success
    assert_includes response.body, "New password must be at least 8 characters"
  end

  test "update when protection not enabled redirects" do
    @user.update!(journal_protection_enabled: false, journal_password_digest: nil)

    patch journal_protection_settings_path, params: {
      current_password: @journal_password,
      new_password: "new_pass123",
      new_password_confirmation: "new_pass123"
    }

    assert_redirected_to journal_protection_settings_path
  end

  test "update re-encrypts seed phrase with new key" do
    new_password = "new_secure_pass123"
    old_encrypted_seed = @user.encrypted_seed_phrase

    patch journal_protection_settings_path, params: {
      current_password: @journal_password,
      new_password: new_password,
      new_password_confirmation: new_password
    }, as: :turbo_stream

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

  test "update invalidates existing session tokens" do
    new_password = "new_secure_pass123"
    cache_key = "journal_session:#{@user.id}:test_token"

    Rails.cache.write(cache_key, "some_data")

    patch journal_protection_settings_path, params: {
      current_password: @journal_password,
      new_password: new_password,
      new_password_confirmation: new_password
    }, as: :turbo_stream

    assert_nil Rails.cache.read(cache_key)
  end

  test "show with disable action_type renders disable dialog" do
    get journal_protection_settings_path(action_type: "disable"), as: :turbo_stream

    assert_response :success
    assert_includes response.body, "disable_protection_dialog"
    assert_includes response.body, "Disable Journal Protection?"
    assert_includes response.body, "decrypt all your journal entries"
    assert_includes response.body, "Enter your password to confirm"
  end

  # destroy action tests
  test "destroy with valid password disables protection" do
    delete journal_protection_settings_path, params: {
      current_password: @journal_password
    }, as: :turbo_stream

    assert_response :success
    @user.reload
    assert_not @user.journal_protection_enabled?
    assert_nil @user.journal_password_digest
    assert_nil @user.encrypted_seed_phrase
    assert_nil @user.journal_encryption_salt
  end

  test "destroy with incorrect password returns error" do
    delete journal_protection_settings_path, params: {
      current_password: "wrong_password"
    }, as: :turbo_stream

    assert_response :success
    assert_includes response.body, "Password is incorrect"
    @user.reload
    assert @user.journal_protection_enabled?
  end

  test "destroy with blank password returns error" do
    delete journal_protection_settings_path, params: {
      current_password: ""
    }, as: :turbo_stream

    assert_response :success
    assert_includes response.body, "Password is required"
  end

  test "destroy when protection not enabled redirects" do
    @user.update!(journal_protection_enabled: false, journal_password_digest: nil)

    delete journal_protection_settings_path, params: {
      current_password: @journal_password
    }

    assert_redirected_to journal_protection_settings_path
  end

  test "destroy queues bulk decrypt job" do
    assert_enqueued_with(job: Journals::BulkDecryptJob) do
      delete journal_protection_settings_path, params: {
        current_password: @journal_password
      }, as: :turbo_stream
    end
  end

  test "destroy shows success toast" do
    delete journal_protection_settings_path, params: {
      current_password: @journal_password
    }, as: :turbo_stream

    assert_includes response.body, "Journal protection disabled"
    assert_includes response.body, "Decrypting entries in the background"
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end
