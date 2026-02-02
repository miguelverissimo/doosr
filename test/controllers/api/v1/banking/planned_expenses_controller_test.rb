require "test_helper"

class Api::V1::Banking::PlannedExpensesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "api_planned@example.com",
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

    @expense = @user.planned_expenses.create!(
      description: "Car Insurance",
      expected_amount: 150.00,
      due_date: Date.current + 2.weeks,
      expense_type: "one_time",
      completed: false
    )
  end

  test "index returns expenses" do
    get api_v1_banking_planned_expenses_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert_equal 1, json["data"].length
    assert_equal "Car Insurance", json["data"][0]["description"]
  end

  test "index filters by status pending" do
    @user.planned_expenses.create!(
      description: "Paid Bill",
      expected_amount: 50.00,
      due_date: Date.current - 1.week,
      expense_type: "one_time",
      completed: true
    )

    get api_v1_banking_planned_expenses_path(status: "pending"), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].all? { |e| e["completed"] == false }
  end

  test "index filters by status completed" do
    get api_v1_banking_planned_expenses_path(status: "completed"), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].all? { |e| e["completed"] == true }
  end

  test "show returns expense" do
    get api_v1_banking_planned_expense_path(@expense), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @expense.id, json["data"]["id"]
  end

  test "show returns 404 for nonexistent" do
    get api_v1_banking_planned_expense_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  test "create planned expense" do
    assert_difference "PlannedExpense.count", 1 do
      post api_v1_banking_planned_expenses_path,
        params: {
          planned_expense: {
            description: "Gym Membership",
            expected_amount: 40.00,
            due_date: (Date.current + 1.month).to_s
          }
        },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Gym Membership", json["data"]["description"]
    assert_equal "one_time", json["data"]["expense_type"]
  end

  test "update planned expense" do
    patch api_v1_banking_planned_expense_path(@expense),
      params: { planned_expense: { expected_amount: 200.00 } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 200.0, json["data"]["expected_amount"]
  end

  test "destroy planned expense" do
    assert_difference "PlannedExpense.count", -1 do
      delete api_v1_banking_planned_expense_path(@expense), headers: @auth_header
    end

    assert_response :ok
  end

  test "mark_completed marks as completed" do
    patch mark_completed_api_v1_banking_planned_expense_path(@expense),
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"]["completed"]

    @expense.reload
    assert @expense.completed
  end

  test "populate_from_recurring delegates to service" do
    post populate_from_recurring_api_v1_banking_planned_expenses_path,
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["meta"].key?("created_count")
  end

  test "returns 401 without auth" do
    get api_v1_banking_planned_expenses_path

    assert_response :unauthorized
  end
end
