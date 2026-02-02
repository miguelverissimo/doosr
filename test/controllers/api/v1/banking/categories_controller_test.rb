require "test_helper"

class Api::V1::Banking::CategoriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "api_categories@example.com",
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

    @category = @user.categories.create!(name: "Food", color: "#FF0000")
    @subcategory = @user.categories.create!(name: "Groceries", color: "#00FF00", parent: @category)
  end

  test "index returns nested categories with subcategories" do
    get api_v1_banking_categories_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    food = json["data"].find { |c| c["name"] == "Food" }
    assert food
    assert food["subcategories"].is_a?(Array)
    assert_equal 1, food["subcategories"].length
  end

  test "index with flat returns flat list" do
    get api_v1_banking_categories_path(flat: "true"), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    names = json["data"].map { |c| c["name"] }
    assert_includes names, "Food"
    assert_includes names, "Groceries"
  end

  test "show returns category with subcategories" do
    get api_v1_banking_category_path(@category), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Food", json["data"]["name"]
    assert json["data"]["subcategories"].is_a?(Array)
  end

  test "show returns 404 for nonexistent" do
    get api_v1_banking_category_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  test "create category" do
    assert_difference "Category.count", 1 do
      post api_v1_banking_categories_path,
        params: { category: { name: "Transport", color: "#0000FF" } },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Transport", json["data"]["name"]
  end

  test "create subcategory with parent_id" do
    post api_v1_banking_categories_path,
      params: { category: { name: "Fast Food", color: "#FF00FF", parent_id: @category.id } },
      headers: @auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal @category.id, json["data"]["parent_id"]
  end

  test "update category" do
    patch api_v1_banking_category_path(@category),
      params: { category: { name: "Food & Dining" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Food & Dining", json["data"]["name"]
  end

  test "destroy category" do
    assert_difference "Category.count", -1 do
      delete api_v1_banking_category_path(@subcategory), headers: @auth_header
    end

    assert_response :ok
  end

  test "returns 401 without auth" do
    get api_v1_banking_categories_path

    assert_response :unauthorized
  end
end
