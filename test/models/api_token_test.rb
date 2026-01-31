require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "tokentest@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + [ "api" ]
    )
  end

  test "generate_token returns a string starting with doo_" do
    token = ApiToken.generate_token
    assert token.start_with?("doo_")
    assert_equal 68, token.length
  end

  test "digest_token returns a SHA256 hex digest" do
    token = "doo_abc123"
    digest = ApiToken.digest_token(token)
    assert_equal Digest::SHA256.hexdigest(token), digest
  end

  test "find_by_plain_token finds token by digest lookup" do
    plain = ApiToken.generate_token
    api_token = @user.api_tokens.create!(
      name: "Test Token",
      token_digest: ApiToken.digest_token(plain),
      token_prefix: plain[0..11]
    )

    found = ApiToken.find_by_plain_token(plain)
    assert_equal api_token.id, found.id
  end

  test "find_by_plain_token returns nil for invalid token" do
    assert_nil ApiToken.find_by_plain_token("doo_invalid")
  end

  test "find_by_plain_token returns nil for blank token" do
    assert_nil ApiToken.find_by_plain_token("")
    assert_nil ApiToken.find_by_plain_token(nil)
  end

  test "validates name presence" do
    token = ApiToken.new(user: @user, name: "", token_digest: "abc", token_prefix: "doo_12345678")
    assert_not token.valid?
    assert_includes token.errors[:name], "can't be blank"
  end

  test "validates token_digest presence" do
    token = ApiToken.new(user: @user, name: "Test", token_digest: "", token_prefix: "doo_12345678")
    assert_not token.valid?
    assert_includes token.errors[:token_digest], "can't be blank"
  end

  test "validates token_digest uniqueness" do
    plain = ApiToken.generate_token
    digest = ApiToken.digest_token(plain)
    @user.api_tokens.create!(name: "First", token_digest: digest, token_prefix: plain[0..11])

    duplicate = @user.api_tokens.build(name: "Second", token_digest: digest, token_prefix: plain[0..11])
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:token_digest], "has already been taken"
  end

  test "touch_last_used! updates last_used_at" do
    plain = ApiToken.generate_token
    api_token = @user.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(plain),
      token_prefix: plain[0..11]
    )

    assert_nil api_token.last_used_at
    api_token.touch_last_used!
    api_token.reload
    assert_not_nil api_token.last_used_at
  end

  test "token_prefix stores first 12 characters" do
    plain = ApiToken.generate_token
    prefix = plain[0..11]
    api_token = @user.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(plain),
      token_prefix: prefix
    )

    assert_equal prefix, api_token.token_prefix
    assert prefix.start_with?("doo_")
  end

  test "destroying user destroys associated api_tokens" do
    plain = ApiToken.generate_token
    @user.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(plain),
      token_prefix: plain[0..11]
    )

    assert_difference "ApiToken.count", -1 do
      @user.destroy
    end
  end
end
