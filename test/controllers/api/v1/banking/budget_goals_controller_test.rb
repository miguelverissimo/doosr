require "test_helper"

class Api::V1::Banking::BudgetGoalsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "api_budgetgoals@example.com",
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
    @goal = @user.budget_goals.create!(
      name: "Monthly Savings",
      goal_type: "savings",
      target_amount: 1000,
      period: "monthly",
      active: true
    )
  end

  test "index returns goals with progress" do
    get api_v1_banking_budget_goals_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert_equal 1, json["data"].length
    assert_equal "Monthly Savings", json["data"][0]["name"]
    assert json["data"][0].key?("progress")
  end

  test "show returns goal with progress" do
    get api_v1_banking_budget_goal_path(@goal), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @goal.id, json["data"]["id"]
    assert json["data"].key?("progress")
    assert json["data"]["progress"].key?("progress_percentage")
  end

  test "show returns 404 for nonexistent" do
    get api_v1_banking_budget_goal_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  test "create budget goal" do
    assert_difference "BudgetGoal.count", 1 do
      post api_v1_banking_budget_goals_path,
        params: {
          budget_goal: {
            name: "Food Budget",
            goal_type: "category_limit",
            category_id: @category.id,
            target_amount: 500,
            period: "monthly",
            active: true
          }
        },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Food Budget", json["data"]["name"]
  end

  test "update budget goal" do
    patch api_v1_banking_budget_goal_path(@goal),
      params: { budget_goal: { target_amount: 2000 } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2000.0, json["data"]["target_amount"]
  end

  test "destroy budget goal" do
    assert_difference "BudgetGoal.count", -1 do
      delete api_v1_banking_budget_goal_path(@goal), headers: @auth_header
    end

    assert_response :ok
  end

  test "returns 401 without auth" do
    get api_v1_banking_budget_goals_path

    assert_response :unauthorized
  end
end
