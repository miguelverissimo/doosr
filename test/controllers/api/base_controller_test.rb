require "test_helper"

class Api::BaseControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apibase@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + [ "api" ]
    )
    @plain_token = ApiToken.generate_token
    @user.api_tokens.create!(
      name: "Test Token",
      token_digest: ApiToken.digest_token(@plain_token),
      token_prefix: @plain_token[0..11]
    )
    @auth_header = { "Authorization" => "Bearer #{@plain_token}" }
  end

  test "returns 401 without authorization header" do
    get api_v1_days_path(format: :json)
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Authentication required", json["error"]
  end

  test "returns 401 with invalid token" do
    get api_v1_days_path(format: :json), headers: { "Authorization" => "Bearer doo_invalid" }
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Invalid API token", json["error"]
  end

  test "returns 401 with malformed authorization header" do
    get api_v1_days_path(format: :json), headers: { "Authorization" => "Basic #{@plain_token}" }
    assert_response :unauthorized
  end

  test "returns 403 without api role" do
    user_no_api = User.create!(
      email: "noapirole@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES
    )
    plain = ApiToken.generate_token
    user_no_api.api_tokens.create!(
      name: "No API Role",
      token_digest: ApiToken.digest_token(plain),
      token_prefix: plain[0..11]
    )

    get api_v1_days_path(format: :json), headers: { "Authorization" => "Bearer #{plain}" }
    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal "API access not enabled for this account", json["error"]
  end

  test "touches last_used_at on authenticated request" do
    api_token = @user.api_tokens.first
    assert_nil api_token.last_used_at

    get api_v1_days_path(format: :json), headers: @auth_header

    api_token.reload
    assert_not_nil api_token.last_used_at
  end
end
