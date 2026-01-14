# frozen_string_literal: true

require "test_helper"

class JournalUnlockControllerTest < ActionDispatch::IntegrationTest
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

    # Encrypt seed phrase with password key
    password_key = Journals::EncryptionService.derive_key(@journal_password, @salt)
    encrypted_seed = Journals::EncryptionService.encrypt(@seed_phrase, password_key)

    @user.update!(
      journal_encryption_salt: @salt,
      journal_password_digest: BCrypt::Password.create(@journal_password),
      encrypted_seed_phrase: [ encrypted_seed[:ciphertext], encrypted_seed[:iv], encrypted_seed[:auth_tag] ].join(":"),
      journal_protection_enabled: true
    )

    # Create a journal for testing
    @journal = Journal.create!(user: @user, date: Date.today)

    sign_in @user
  end

  test "new returns turbo_stream with unlock dialog" do
    get new_journal_unlock_path, as: :turbo_stream

    assert_response :success
  end

  test "create with valid password unlocks journal and returns session token" do
    post journal_unlock_path, params: { password: @journal_password }, as: :turbo_stream, headers: { "HTTP_REFERER" => journal_path(@journal) }

    assert_response :success
    assert_match(/journal:unlocked/, response.body)
  end

  test "create with blank password returns error" do
    post journal_unlock_path, params: { password: "" }, as: :turbo_stream

    assert_response :success
    assert_match(/Password is required/, response.body)
  end

  test "create with invalid password returns error" do
    post journal_unlock_path, params: { password: "wrong_password" }, as: :turbo_stream

    assert_response :success
    assert_match(/Invalid password/, response.body)
  end

  test "create when protection not enabled returns error" do
    @user.update!(journal_protection_enabled: false, journal_password_digest: nil)

    post journal_unlock_path, params: { password: @journal_password }, as: :turbo_stream

    assert_response :success
    assert_match(/Journal protection is not enabled/, response.body)
  end

  test "create stores session in cache" do
    # Use memory store for this test since test env uses null_store
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    begin
      post journal_unlock_path, params: { password: @journal_password }, as: :turbo_stream, headers: { "HTTP_REFERER" => journal_path(@journal) }

      assert_response :success

      # Verify that a session was cached (we can't easily extract the token in tests)
      # Just verify that at least one cache entry exists for this user
      cache_keys = Rails.cache.instance_variable_get(:@data).keys.select { |k| k.to_s.start_with?("journal_session:#{@user.id}:") }
      assert cache_keys.any?, "Expected at least one session to be cached"

      # Verify the cached data structure
      cached_data = Rails.cache.read(cache_keys.first)
      assert cached_data.present?, "Expected session to be cached"
      assert_equal @user.id, cached_data[:user_id]
      assert cached_data[:encryption_key].present?
    ensure
      Rails.cache = original_cache
    end
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end
