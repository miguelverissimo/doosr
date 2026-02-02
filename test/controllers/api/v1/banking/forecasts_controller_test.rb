require "test_helper"

class Api::V1::Banking::ForecastsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "api_forecasts@example.com",
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

    @reminder = @user.payment_reminders.create!(
      title: "Rent",
      expected_amount: 1200.00,
      cutoff_date: Date.current + 30.days,
      active: true,
      reminder_days_before: [ 7, 3, 0 ]
    )

    @expense = @user.planned_expenses.create!(
      description: "Car Insurance",
      expected_amount: 150.00,
      due_date: Date.current + 2.weeks,
      expense_type: "one_time",
      completed: false
    )

    @user.bank_transactions.create!(
      date: Date.current - 1.week,
      description: "Grocery shopping",
      value: -80.00,
      row_hash: Digest::SHA256.hexdigest("forecast-api-1")
    )
  end

  test "index returns forecast overview" do
    get api_v1_banking_forecasts_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].key?("payment_reminders")
    assert json["data"]["payment_reminders"].is_a?(Array)
    assert json["data"].key?("section_spending")
    assert json["data"]["section_spending"].is_a?(Array)
  end

  test "index includes payment reminder details" do
    get api_v1_banking_forecasts_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    reminders = json["data"]["payment_reminders"]
    assert reminders.length >= 1
    reminder = reminders.find { |r| r["id"] == @reminder.id }
    assert_not_nil reminder
    assert_equal "Rent", reminder["title"]
    assert_equal 1200.0, reminder["expected_amount"]
  end

  test "calendar returns planned expenses for next 12 weeks" do
    get calendar_api_v1_banking_forecasts_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert json["meta"].key?("start_date")
    assert json["meta"].key?("end_date")
    assert json["meta"].key?("total_count")

    expense = json["data"].find { |e| e["id"] == @expense.id }
    assert_not_nil expense
    assert_equal "Car Insurance", expense["description"]
    assert_equal 150.0, expense["expected_amount"]
  end

  test "calendar excludes expenses outside 12 week window" do
    far_expense = @user.planned_expenses.create!(
      description: "Far Future",
      expected_amount: 500.00,
      due_date: Date.current + 6.months,
      expense_type: "one_time",
      completed: false
    )

    get calendar_api_v1_banking_forecasts_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    ids = json["data"].map { |e| e["id"] }
    assert_not_includes ids, far_expense.id
  end

  test "projections returns cash flow data" do
    get projections_api_v1_banking_forecasts_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].key?("current_balance")
    assert json["data"].key?("projections")
    assert json["data"]["projections"].is_a?(Array)
    assert json["data"].key?("warnings")
    assert json["data"]["warnings"].is_a?(Array)

    if json["data"]["projections"].any?
      projection = json["data"]["projections"].first
      assert projection.key?("week_start")
      assert projection.key?("week_end")
      assert projection.key?("starting_balance")
      assert projection.key?("ending_balance")
    end
  end

  test "returns 401 without auth" do
    get api_v1_banking_forecasts_path

    assert_response :unauthorized
  end
end
