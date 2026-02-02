require "test_helper"

class Api::V1::Banking::BankAccountsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "api_bankaccts@example.com",
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

    @account = @user.bank_accounts.create!(name: "Main Account", account_type: "checking", active: true)
    @user.bank_transactions.create!(
      date: Date.current,
      description: "Test",
      value: -50.00,
      bank_account: @account,
      row_hash: Digest::SHA256.hexdigest("bankacct-test-1")
    )
  end

  test "index returns accounts with transaction counts" do
    get api_v1_banking_bank_accounts_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert_equal 1, json["data"].length
    assert_equal 1, json["data"][0]["transactions_count"]
  end

  test "index filters by active" do
    @user.bank_accounts.create!(name: "Inactive", account_type: "savings", active: false)

    get api_v1_banking_bank_accounts_path(active: "true"), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].all? { |a| a["active"] }
  end

  test "show returns account" do
    get api_v1_banking_bank_account_path(@account), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @account.id, json["data"]["id"]
    assert_equal "Main Account", json["data"]["name"]
  end

  test "show returns 404 for nonexistent" do
    get api_v1_banking_bank_account_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  test "create bank account" do
    assert_difference "BankAccount.count", 1 do
      post api_v1_banking_bank_accounts_path,
        params: { bank_account: { name: "Savings", account_type: "savings" } },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Savings", json["data"]["name"]
  end

  test "create fails with missing name" do
    post api_v1_banking_bank_accounts_path,
      params: { bank_account: { name: "" } },
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  test "update bank account" do
    patch api_v1_banking_bank_account_path(@account),
      params: { bank_account: { name: "Updated Account" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Updated Account", json["data"]["name"]
  end

  test "destroy bank account" do
    assert_difference "BankAccount.count", -1 do
      delete api_v1_banking_bank_account_path(@account), headers: @auth_header
    end

    assert_response :ok
  end

  test "returns 401 without auth" do
    get api_v1_banking_bank_accounts_path

    assert_response :unauthorized
  end

  test "returns 403 without banking role" do
    user2 = User.create!(
      email: "nobanking_accts@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + [ "api" ]
    )
    token = ApiToken.generate_token
    user2.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(token),
      token_prefix: token[0..11]
    )

    get api_v1_banking_bank_accounts_path,
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end
end
