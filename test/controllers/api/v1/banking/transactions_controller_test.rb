require "test_helper"

class Api::V1::Banking::TransactionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apibanking@example.com",
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

    @bank_account = @user.bank_accounts.create!(name: "Main Account", account_type: "checking")

    @transaction = @user.bank_transactions.create!(
      date: Date.current,
      description: "Test purchase",
      value: -50.00,
      bank_account: @bank_account,
      row_hash: Digest::SHA256.hexdigest("#{Date.current.iso8601}|test purchase|-50.0")
    )
  end

  # === INDEX ===

  test "index returns transactions with pagination and totals" do
    get api_v1_banking_transactions_path(start_date: "all", end_date: "all"),
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert_equal 1, json["meta"]["total_count"]
    assert json["meta"].key?("total_income")
    assert json["meta"].key?("total_expenses")
    assert json["meta"].key?("net_balance")
  end

  test "index filters by date range" do
    old_transaction = @user.bank_transactions.create!(
      date: Date.current - 1.year,
      description: "Old purchase",
      value: -25.00,
      row_hash: Digest::SHA256.hexdigest("#{(Date.current - 1.year).iso8601}|old purchase|-25.0")
    )

    get api_v1_banking_transactions_path(
      start_date: (Date.current - 1.month).to_s,
      end_date: Date.current.to_s
    ), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    ids = json["data"].map { |t| t["id"] }
    assert_includes ids, @transaction.id
    assert_not_includes ids, old_transaction.id
  end

  test "index filters by search term" do
    get api_v1_banking_transactions_path(start_date: "all", search: "purchase"),
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json["data"].length
  end

  test "index filters transfers" do
    transfer = @user.bank_transactions.create!(
      date: Date.current,
      description: "Transfer to savings",
      value: -100.00,
      is_transfer: true,
      row_hash: Digest::SHA256.hexdigest("#{Date.current.iso8601}|transfer to savings|-100.0")
    )

    get api_v1_banking_transactions_path(start_date: "all", transfer_filter: "exclude"),
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    ids = json["data"].map { |t| t["id"] }
    assert_not_includes ids, transfer.id
    assert_includes ids, @transaction.id
  end

  # === SHOW ===

  test "show returns a transaction" do
    get api_v1_banking_transaction_path(@transaction), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @transaction.id, json["data"]["id"]
    assert_equal "Test purchase", json["data"]["description"]
    assert_equal(-50.0, json["data"]["value"])
  end

  test "show returns 404 for nonexistent transaction" do
    get api_v1_banking_transaction_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  # === CREATE ===

  test "create transaction" do
    assert_difference "BankTransaction.count", 1 do
      post api_v1_banking_transactions_path,
        params: {
          bank_transaction: {
            date: Date.current.to_s,
            description: "New expense",
            value: "-75.50",
            bank_account_id: @bank_account.id
          }
        },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New expense", json["data"]["description"]
    assert_equal(-75.5, json["data"]["value"])
    assert_equal @bank_account.id, json["data"]["bank_account_id"]
  end

  test "create transaction fails with missing fields" do
    post api_v1_banking_transactions_path,
      params: { bank_transaction: { description: "" } },
      headers: @auth_header

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].any?
  end

  # === UPDATE ===

  test "update transaction" do
    patch api_v1_banking_transaction_path(@transaction),
      params: { bank_transaction: { description: "Updated description" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Updated description", json["data"]["description"]
  end

  test "update nonexistent transaction returns 404" do
    patch api_v1_banking_transaction_path(id: 999999),
      params: { bank_transaction: { description: "x" } },
      headers: @auth_header

    assert_response :not_found
  end

  # === DESTROY ===

  test "destroy transaction" do
    assert_difference "BankTransaction.count", -1 do
      delete api_v1_banking_transaction_path(@transaction), headers: @auth_header
    end

    assert_response :ok
  end

  test "destroy nonexistent transaction returns 404" do
    delete api_v1_banking_transaction_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  # === TOGGLE TRANSFER ===

  test "toggle_transfer toggles is_transfer flag" do
    assert_not @transaction.is_transfer

    patch toggle_transfer_api_v1_banking_transaction_path(@transaction),
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"]["is_transfer"]

    @transaction.reload
    assert @transaction.is_transfer
  end

  # === BULK DESTROY ===

  test "bulk_destroy removes multiple transactions" do
    t2 = @user.bank_transactions.create!(
      date: Date.current,
      description: "Another purchase",
      value: -30.00,
      row_hash: Digest::SHA256.hexdigest("#{Date.current.iso8601}|another purchase|-30.0")
    )

    assert_difference "BankTransaction.count", -2 do
      delete bulk_destroy_api_v1_banking_transactions_path,
        params: { ids: [ @transaction.id, t2.id ] },
        headers: @auth_header
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json["meta"]["destroyed_count"]
  end

  # === AUTHORIZATION ===

  test "returns 401 without auth token" do
    get api_v1_banking_transactions_path

    assert_response :unauthorized
  end

  test "returns 403 without banking role" do
    user_no_banking = User.create!(
      email: "nobanking@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + [ "api" ]
    )
    token = ApiToken.generate_token
    user_no_banking.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(token),
      token_prefix: token[0..11]
    )

    get api_v1_banking_transactions_path,
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end
end
