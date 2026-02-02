require "test_helper"

class Api::V1::Banking::RecurringGroupsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "api_recurring@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + %w[api banking]
    )
    @plain_token = ApiToken.generate_token
    @user.api_tokens.create!(
      name: "Test Token",
      token_digest: ApiToken.digest_token(@plain_token),
      token_prefix: @plain_token[0..11]
    )
    @auth_header = { "Authorization" => "Bearer #{@plain_token}" }

    @group = @user.recurring_groups.create!(
      name: "Netflix",
      description_pattern: "netflix",
      frequency: "monthly",
      average_amount: -15.99,
      active: true
    )

    @user.bank_transactions.create!(
      date: Date.current,
      description: "Netflix Subscription",
      value: -15.99,
      row_hash: Digest::SHA256.hexdigest("recurring-api-1"),
      recurring_group: @group
    )
  end

  test "index returns active groups with total_monthly" do
    get api_v1_banking_recurring_groups_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert_equal 1, json["data"].length
    assert_equal "Netflix", json["data"][0]["name"]
    assert json["meta"]["total_monthly"].is_a?(Numeric)
  end

  test "show returns group with transactions" do
    get api_v1_banking_recurring_group_path(@group), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @group.id, json["data"]["id"]
    assert json["data"]["transactions"].is_a?(Array)
    assert json["data"]["transactions"].length >= 1
  end

  test "show returns 404 for nonexistent" do
    get api_v1_banking_recurring_group_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  test "detect returns 202 and enqueues job" do
    assert_enqueued_with(job: Banking::RecurringDetectionJob) do
      post detect_api_v1_banking_recurring_groups_path, headers: @auth_header
    end

    assert_response :accepted
    json = JSON.parse(response.body)
    assert json["meta"]["message"].present?
  end

  test "returns 401 without auth" do
    get api_v1_banking_recurring_groups_path

    assert_response :unauthorized
  end
end
