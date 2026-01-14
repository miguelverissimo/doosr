# frozen_string_literal: true

require "test_helper"

class Journals::BulkDecryptJobTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test-bulk-decrypt@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @journal = Journal.create!(
      user: @user,
      date: Date.current
    )

    @encryption_service = Journals::EncryptionService.new
    @salt = @encryption_service.generate_salt
    @key = @encryption_service.derive_key("journal_password", @salt)

    @user.update!(
      journal_protection_enabled: true,
      journal_encryption_salt: @salt,
      journal_password_digest: BCrypt::Password.create("journal_password")
    )
  end

  def teardown
    @user.destroy!
  end

  test "decrypts all encrypted fragments for a user" do
    result = @encryption_service.encrypt("Secret content", @key)
    fragment = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: nil,
      encrypted_content: result[:ciphertext],
      content_iv: "#{result[:iv]}:#{result[:auth_tag]}"
    )

    Journals::BulkDecryptJob.perform_now(@user.id, @key)

    fragment.reload
    assert_equal "Secret content", fragment.content
    assert_nil fragment.encrypted_content
    assert_nil fragment.content_iv
  end

  test "skips fragments without encrypted content" do
    fragment = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: "Plain content",
      encrypted_content: nil,
      content_iv: nil
    )

    Journals::BulkDecryptJob.perform_now(@user.id, @key)

    fragment.reload
    assert_equal "Plain content", fragment.content
    assert_nil fragment.encrypted_content
  end

  test "handles multiple fragments" do
    fragments = 3.times.map do |i|
      result = @encryption_service.encrypt("Content #{i}", @key)
      JournalFragment.create!(
        user: @user,
        journal: @journal,
        content: nil,
        encrypted_content: result[:ciphertext],
        content_iv: "#{result[:iv]}:#{result[:auth_tag]}"
      )
    end

    Journals::BulkDecryptJob.perform_now(@user.id, @key)

    fragments.each_with_index do |fragment, i|
      fragment.reload
      assert_equal "Content #{i}", fragment.content
      assert_nil fragment.encrypted_content
      assert_nil fragment.content_iv
    end
  end

  test "continues on individual fragment failure" do
    good_result = @encryption_service.encrypt("Good content", @key)
    good_fragment = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: nil,
      encrypted_content: good_result[:ciphertext],
      content_iv: "#{good_result[:iv]}:#{good_result[:auth_tag]}"
    )

    bad_fragment = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: nil,
      encrypted_content: "invalid_ciphertext",
      content_iv: "invalid_iv:invalid_auth_tag"
    )

    Journals::BulkDecryptJob.perform_now(@user.id, @key)

    good_fragment.reload
    assert_equal "Good content", good_fragment.content
    assert_nil good_fragment.encrypted_content

    bad_fragment.reload
    assert_equal "invalid_ciphertext", bad_fragment.encrypted_content
  end

  test "only processes fragments belonging to the user" do
    other_user = User.create!(
      email: "other-bulk-decrypt@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    other_journal = Journal.create!(user: other_user, date: Date.current)
    other_fragment = JournalFragment.create!(
      user: other_user,
      journal: other_journal,
      content: nil,
      encrypted_content: "other_encrypted",
      content_iv: "iv:tag"
    )

    Journals::BulkDecryptJob.perform_now(@user.id, @key)

    other_fragment.reload
    assert_equal "other_encrypted", other_fragment.encrypted_content
  ensure
    other_user&.destroy!
  end
end
