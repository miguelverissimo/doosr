require "test_helper"

class Api::V1::Banking::TransferPatternsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "api_transferpat@example.com",
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

    @pattern = @user.transfer_patterns.create!(pattern: "transfer to")

    @transfer_txn = @user.bank_transactions.create!(
      date: Date.current,
      description: "Transfer to Savings",
      value: -500.00,
      row_hash: Digest::SHA256.hexdigest("transferpat-api-1"),
      is_transfer: true
    )
  end

  test "index returns patterns with matched counts" do
    get api_v1_banking_transfer_patterns_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert_equal 1, json["data"].length
    assert json["data"][0]["matched_transactions_count"] >= 1
  end

  test "show returns pattern with matched count" do
    get api_v1_banking_transfer_pattern_path(@pattern), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @pattern.id, json["data"]["id"]
    assert json["data"]["matched_transactions_count"] >= 1
  end

  test "create pattern" do
    assert_difference "TransferPattern.count", 1 do
      post api_v1_banking_transfer_patterns_path,
        params: { transfer_pattern: { pattern: "wire payment", label: "Wire" } },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "wire payment", json["data"]["pattern"]
  end

  test "create with apply_to_existing marks matching transactions" do
    non_transfer = @user.bank_transactions.create!(
      date: Date.current,
      description: "Wire Payment to Bank",
      value: -1000.00,
      row_hash: Digest::SHA256.hexdigest("transferpat-api-2"),
      is_transfer: false
    )

    post api_v1_banking_transfer_patterns_path,
      params: {
        transfer_pattern: { pattern: "wire payment" },
        apply_to_existing: "1"
      },
      headers: @auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert json["meta"]["applied_count"] >= 1

    non_transfer.reload
    assert non_transfer.is_transfer
  end

  test "update triggers rematch" do
    patch api_v1_banking_transfer_pattern_path(@pattern),
      params: { transfer_pattern: { pattern: "transfer" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["meta"].key?("applied_count")
  end

  test "destroy unmarks matching transactions" do
    delete api_v1_banking_transfer_pattern_path(@pattern), headers: @auth_header

    assert_response :ok
    @transfer_txn.reload
    assert_not @transfer_txn.is_transfer
  end

  test "returns 401 without auth" do
    get api_v1_banking_transfer_patterns_path

    assert_response :unauthorized
  end
end
