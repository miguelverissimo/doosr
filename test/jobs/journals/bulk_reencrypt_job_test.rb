# frozen_string_literal: true

require "test_helper"

class Journals::BulkReencryptJobTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test-bulk-reencrypt@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @journal = Journal.create!(
      user: @user,
      date: Date.current
    )

    @encryption_service = Journals::EncryptionService.new
    @salt = @encryption_service.generate_salt
    @old_key = @encryption_service.derive_key("old_password", @salt)
    @new_key = @encryption_service.derive_key("new_password", @salt)
  end

  def teardown
    @user.destroy!
  end

  test "re-encrypts all encrypted fragments for a user" do
    original_content1 = "First fragment content"
    original_content2 = "Second fragment content"

    fragment1 = create_encrypted_fragment(original_content1, @old_key)
    fragment2 = create_encrypted_fragment(original_content2, @old_key)

    Journals::BulkReencryptJob.perform_now(@user.id, @old_key, @new_key)

    fragment1.reload
    fragment2.reload

    decrypted1 = fragment1.decrypted_content(@new_key)
    decrypted2 = fragment2.decrypted_content(@new_key)

    assert_equal original_content1, decrypted1
    assert_equal original_content2, decrypted2
  end

  test "skips fragments without encrypted content" do
    fragment = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: "Plain unencrypted content"
    )

    Journals::BulkReencryptJob.perform_now(@user.id, @old_key, @new_key)

    fragment.reload
    assert_equal "Plain unencrypted content", fragment.content
    assert_nil fragment.encrypted_content
    assert_nil fragment.content_iv
  end

  test "content remains accessible with new key after re-encryption" do
    original_content = "Hello, World! 🔐"
    fragment = create_encrypted_fragment(original_content, @old_key)

    Journals::BulkReencryptJob.perform_now(@user.id, @old_key, @new_key)

    fragment.reload
    decrypted = fragment.decrypted_content(@new_key)

    assert_equal original_content, decrypted
  end

  test "content no longer accessible with old key after re-encryption" do
    original_content = "Secret content"
    fragment = create_encrypted_fragment(original_content, @old_key)

    Journals::BulkReencryptJob.perform_now(@user.id, @old_key, @new_key)

    fragment.reload
    assert_raises(Journals::EncryptionService::DecryptionError) do
      fragment.decrypted_content(@old_key)
    end
  end

  test "handles decryption errors gracefully" do
    fragment = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: "placeholder"
    )
    fragment.update_columns(
      encrypted_content: "invalid_encrypted_data",
      content_iv: "invalid_iv:invalid_tag",
      content: nil
    )

    assert_nothing_raised do
      Journals::BulkReencryptJob.perform_now(@user.id, @old_key, @new_key)
    end
  end

  private

  def create_encrypted_fragment(content, key)
    fragment = JournalFragment.create!(
      user: @user,
      journal: @journal,
      content: content
    )

    result = @encryption_service.encrypt(content, key)
    fragment.update_columns(
      encrypted_content: result[:ciphertext],
      content_iv: "#{result[:iv]}:#{result[:auth_tag]}",
      content: nil
    )

    fragment
  end
end
