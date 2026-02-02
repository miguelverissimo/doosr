require "test_helper"

class Api::V1::Banking::CategoryPatternsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "api_catpatterns@example.com",
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

    @category = @user.categories.create!(name: "Groceries", color: "#00FF00")
    @pattern = @user.category_patterns.create!(pattern: "grocery", category: @category)

    @matching_txn = @user.bank_transactions.create!(
      date: Date.current,
      description: "Grocery Store",
      value: -30.00,
      row_hash: Digest::SHA256.hexdigest("catpattern-api-1"),
      category_pattern: @pattern
    )
  end

  test "index returns patterns with matched counts" do
    get api_v1_banking_category_patterns_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert_equal 1, json["data"].length
    assert json["data"][0]["matched_transactions_count"] >= 0
    assert_equal "Groceries", json["data"][0]["category_name"]
  end

  test "show returns pattern" do
    get api_v1_banking_category_pattern_path(@pattern), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @pattern.id, json["data"]["id"]
    assert_equal "grocery", json["data"]["pattern"]
  end

  test "create pattern" do
    category2 = @user.categories.create!(name: "Dining", color: "#FF0000")

    assert_difference "CategoryPattern.count", 1 do
      post api_v1_banking_category_patterns_path,
        params: { category_pattern: { pattern: "restaurant", category_id: category2.id } },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "restaurant", json["data"]["pattern"]
  end

  test "create with apply_to_existing applies to matching transactions" do
    uncategorized_txn = @user.bank_transactions.create!(
      date: Date.current,
      description: "Pizza Place Delivery",
      value: -20.00,
      row_hash: Digest::SHA256.hexdigest("catpattern-api-2")
    )
    category2 = @user.categories.create!(name: "Dining", color: "#FF0000")

    post api_v1_banking_category_patterns_path,
      params: {
        category_pattern: { pattern: "pizza", category_id: category2.id },
        apply_to_existing: "1"
      },
      headers: @auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert json["meta"]["applied_count"] >= 1

    uncategorized_txn.reload
    assert_equal [ category2.id ], uncategorized_txn.categories.pluck(:id)
  end

  test "update triggers rematch" do
    patch api_v1_banking_category_pattern_path(@pattern),
      params: { category_pattern: { pattern: "grocery store" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["meta"]["rematch_stats"].present?
  end

  test "destroy pattern" do
    assert_difference "CategoryPattern.count", -1 do
      delete api_v1_banking_category_pattern_path(@pattern), headers: @auth_header
    end

    assert_response :ok
  end

  test "returns 401 without auth" do
    get api_v1_banking_category_patterns_path

    assert_response :unauthorized
  end
end
