# frozen_string_literal: true

require "test_helper"

class Journals::BulkEncryptJobTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test-bulk-encrypt@example.com",
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
  end

  def teardown
    @user.destroy!
  end

  test "encrypts all unencrypted fragments for a user" do
    fragment1 = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: "First fragment content"
    )
    fragment2 = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: "Second fragment content"
    )

    Journals::BulkEncryptJob.perform_now(@user.id, @key)

    fragment1.reload
    fragment2.reload

    assert_not_nil fragment1.encrypted_content
    assert_not_nil fragment1.content_iv
    assert_nil fragment1.content

    assert_not_nil fragment2.encrypted_content
    assert_not_nil fragment2.content_iv
    assert_nil fragment2.content
  end

  test "skips already encrypted fragments" do
    fragment = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: "Original content"
    )

    result = @encryption_service.encrypt("Already encrypted", @key)
    fragment.update_columns(
      encrypted_content: result[:ciphertext],
      content_iv: "#{result[:iv]}:#{result[:auth_tag]}"
    )
    original_encrypted_content = fragment.encrypted_content

    Journals::BulkEncryptJob.perform_now(@user.id, @key)

    fragment.reload
    assert_equal original_encrypted_content, fragment.encrypted_content
  end

  test "skips fragments with blank content" do
    fragment = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: "placeholder"
    )
    fragment.update_columns(content: nil)

    Journals::BulkEncryptJob.perform_now(@user.id, @key)

    fragment.reload
    assert_nil fragment.encrypted_content
    assert_nil fragment.content_iv
  end

  test "encrypted content can be decrypted with same key" do
    original_content = "Hello, World! 🔐"
    fragment = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: original_content
    )

    Journals::BulkEncryptJob.perform_now(@user.id, @key)

    fragment.reload
    iv, auth_tag = fragment.content_iv.split(":")
    decrypted = @encryption_service.decrypt(
      fragment.encrypted_content,
      iv,
      @key,
      auth_tag: auth_tag
    )

    assert_equal original_content, decrypted
  end
end
