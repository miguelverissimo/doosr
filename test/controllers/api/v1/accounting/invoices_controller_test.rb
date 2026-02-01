require "test_helper"

class Api::V1::Accounting::InvoicesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apiaccounting@example.com",
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

    # Create address for provider
    @provider = @user.addresses.create!(
      name: "My Company",
      full_address: "123 Main St, City",
      country: "CA",
      address_type: :user
    )

    # Create address for customer
    @customer_address = @user.addresses.create!(
      name: "Client Inc",
      full_address: "456 Client Ave, Town",
      country: "US",
      address_type: :customer
    )

    @customer = @user.customers.create!(
      name: "Test Client",
      address: @customer_address
    )

    @invoice = @user.invoices.create!(
      number: 1,
      year: 2025,
      display_number: "1/2025",
      customer: @customer,
      provider: @provider,
      currency: :EUR,
      state: :draft,
      subtotal: 1000,
      tax: 210,
      discount: 0,
      total: 1210
    )
  end

  # === INDEX ===

  test "index returns invoices with pagination" do
    get api_v1_accounting_invoices_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert_equal 1, json["meta"]["total_count"]
    assert_equal 1, json["meta"]["page"]
  end

  test "index filters by state" do
    get api_v1_accounting_invoices_path(filter: "draft"), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json["data"].length
    assert_equal "draft", json["data"].first["state"]

    get api_v1_accounting_invoices_path(filter: "paid"), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 0, json["data"].length
  end

  test "index filters by year" do
    get api_v1_accounting_invoices_path(year: 2025), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json["data"].length

    get api_v1_accounting_invoices_path(year: 2024), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 0, json["data"].length
  end

  test "index filters by customer" do
    get api_v1_accounting_invoices_path(customer_id: @customer.id), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json["data"].length
  end

  # === SHOW ===

  test "show returns invoice with items" do
    get api_v1_accounting_invoice_path(@invoice), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @invoice.id, json["data"]["id"]
    assert_equal "1/2025", json["data"]["display_number"]
    assert_equal "draft", json["data"]["state"]
    assert_equal "Test Client", json["data"]["customer_name"]
    assert json["data"].key?("items")
    assert json["data"].key?("notes")
  end

  test "show returns 404 for nonexistent invoice" do
    get api_v1_accounting_invoice_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  # === UPDATE ===

  test "update invoice state" do
    patch api_v1_accounting_invoice_path(@invoice),
      params: { invoice: { state: "sent" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "sent", json["data"]["state"]

    @invoice.reload
    assert @invoice.sent?
  end

  test "update invoice notes and dates" do
    patch api_v1_accounting_invoice_path(@invoice),
      params: {
        invoice: {
          notes: "Payment due in 30 days",
          issued_at: "2025-06-01",
          due_at: "2025-07-01"
        }
      },
      headers: @auth_header

    assert_response :ok
  end

  test "update nonexistent invoice returns 404" do
    patch api_v1_accounting_invoice_path(id: 999999),
      params: { invoice: { state: "sent" } },
      headers: @auth_header

    assert_response :not_found
  end

  # === DESTROY ===

  test "destroy invoice" do
    assert_difference "Accounting::Invoice.count", -1 do
      delete api_v1_accounting_invoice_path(@invoice), headers: @auth_header
    end

    assert_response :ok
  end

  test "destroy nonexistent invoice returns 404" do
    delete api_v1_accounting_invoice_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  # === AUTHORIZATION ===

  test "returns 401 without auth token" do
    get api_v1_accounting_invoices_path

    assert_response :unauthorized
  end

  test "returns 403 without accounting role" do
    user_no_acct = User.create!(
      email: "noacct@example.com",
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

    get api_v1_accounting_invoices_path,
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end
end
