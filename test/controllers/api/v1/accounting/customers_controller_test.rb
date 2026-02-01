require "test_helper"

class Api::V1::Accounting::CustomersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apicustomers@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + %w[api accounting]
    )
    @plain_token = ApiToken.generate_token
    @user.api_tokens.create!(
      name: "Test Token",
      token_digest: ApiToken.digest_token(@plain_token),
      token_prefix: @plain_token[0..11]
    )
    @auth_header = { "Authorization" => "Bearer #{@plain_token}" }

    @address = @user.addresses.create!(
      name: "Client Corp",
      full_address: "789 Client Blvd, Metropolis",
      country: "DE",
      address_type: :customer
    )

    @customer = @user.customers.create!(
      name: "Client Corp",
      address: @address
    )
  end

  # === INDEX ===

  test "index returns customers ordered by name" do
    address2 = @user.addresses.create!(
      name: "Alpha Inc",
      full_address: "1 Alpha St",
      country: "FR",
      address_type: :customer
    )
    customer2 = @user.customers.create!(name: "Alpha Inc", address: address2)

    get api_v1_accounting_customers_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json["data"].length
    assert_equal 2, json["meta"]["total_count"]

    # Alpha Inc should come first (ordered by name)
    assert_equal "Alpha Inc", json["data"].first["name"]
    assert_equal "Client Corp", json["data"].second["name"]
  end

  test "index includes address info" do
    get api_v1_accounting_customers_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    customer_data = json["data"].first
    assert_equal "Client Corp", customer_data["name"]
    assert customer_data["address"].present?
    assert_equal @address.id, customer_data["address"]["id"]
    assert_equal "789 Client Blvd, Metropolis", customer_data["address"]["full_address"]
    assert_equal "DE", customer_data["address"]["country"]
  end

  # === SHOW ===

  test "show returns a customer" do
    get api_v1_accounting_customer_path(@customer), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @customer.id, json["data"]["id"]
    assert_equal "Client Corp", json["data"]["name"]
    assert json["data"]["address"].present?
  end

  test "show returns 404 for nonexistent customer" do
    get api_v1_accounting_customer_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  # === AUTHORIZATION ===

  test "returns 401 without auth token" do
    get api_v1_accounting_customers_path

    assert_response :unauthorized
  end

  test "returns 403 without accounting role" do
    user_no_acct = User.create!(
      email: "noacctcust@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + [ "api" ]
    )
    token = ApiToken.generate_token
    user_no_acct.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(token),
      token_prefix: token[0..11]
    )

    get api_v1_accounting_customers_path,
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end
end
