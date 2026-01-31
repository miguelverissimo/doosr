require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apitokens@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + [ "api" ]
    )
    sign_in @user
  end

  test "index renders the API tokens page" do
    get api_tokens_path
    assert_response :success
    assert_includes response.body, "API Access"
  end

  test "index lists existing tokens" do
    plain = ApiToken.generate_token
    @user.api_tokens.create!(
      name: "My Script Token",
      token_digest: ApiToken.digest_token(plain),
      token_prefix: plain[0..11]
    )

    get api_tokens_path
    assert_response :success
    assert_includes response.body, "My Script Token"
    assert_includes response.body, plain[0..11]
  end

  test "create generates a new token and returns turbo_stream" do
    assert_difference "ApiToken.count", 1 do
      post api_tokens_path, params: { name: "New Token" }, as: :turbo_stream
    end
    assert_response :success

    token = @user.api_tokens.last
    assert_equal "New Token", token.name
    assert token.token_prefix.start_with?("doo_")
  end

  test "create shows the plain token in dialog" do
    post api_tokens_path, params: { name: "Show Token" }, as: :turbo_stream
    assert_response :success
    # The response should contain a turbo_stream that includes the token created dialog
    assert_includes response.body, "Token Created"
    assert_includes response.body, "won&#39;t be shown again"
  end

  test "create with blank name returns errors" do
    assert_no_difference "ApiToken.count" do
      post api_tokens_path, params: { name: "" }, as: :turbo_stream
    end
    assert_response :success
    assert_includes response.body, "token_form_errors"
  end

  test "destroy revokes a token" do
    plain = ApiToken.generate_token
    api_token = @user.api_tokens.create!(
      name: "To Delete",
      token_digest: ApiToken.digest_token(plain),
      token_prefix: plain[0..11]
    )

    assert_difference "ApiToken.count", -1 do
      delete api_token_path(api_token), as: :turbo_stream
    end
    assert_response :success
  end

  test "destroy removes the token row via turbo_stream" do
    plain = ApiToken.generate_token
    api_token = @user.api_tokens.create!(
      name: "Remove Me",
      token_digest: ApiToken.digest_token(plain),
      token_prefix: plain[0..11]
    )

    delete api_token_path(api_token), as: :turbo_stream
    assert_response :success
    assert_includes response.body, "api_token_#{api_token.id}"
  end

  test "cannot access without api role" do
    user_no_api = User.create!(
      email: "noapirole2@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES
    )
    delete_session
    sign_in user_no_api

    get api_tokens_path
    assert_response :not_found
  end

  test "cannot access without authentication" do
    delete_session

    get api_tokens_path
    assert_response :redirect
  end

  test "cannot destroy another user's token" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + [ "api" ]
    )
    plain = ApiToken.generate_token
    other_token = other_user.api_tokens.create!(
      name: "Other Token",
      token_digest: ApiToken.digest_token(plain),
      token_prefix: plain[0..11]
    )

    assert_no_difference "ApiToken.count" do
      delete api_token_path(other_token), as: :turbo_stream
    end
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end

  def delete_session
    delete destroy_user_session_path
  end
end
