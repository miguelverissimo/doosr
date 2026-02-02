require "test_helper"

class Api::V1::Banking::PaymentRemindersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "api_reminders@example.com",
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

    @reminder = @user.payment_reminders.create!(
      title: "Rent",
      expected_amount: 1200.00,
      cutoff_date: Date.current + 30.days,
      active: true,
      reminder_days_before: [ 7, 3, 0 ]
    )
  end

  test "index returns reminders" do
    get api_v1_banking_payment_reminders_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert_equal 1, json["data"].length
    assert_equal "Rent", json["data"][0]["title"]
  end

  test "index filters by active" do
    @user.payment_reminders.create!(
      title: "Inactive",
      cutoff_date: Date.current + 60.days,
      active: false,
      reminder_days_before: [ 7 ]
    )

    get api_v1_banking_payment_reminders_path(active: "true"), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].all? { |r| r["active"] }
  end

  test "show returns reminder" do
    get api_v1_banking_payment_reminder_path(@reminder), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @reminder.id, json["data"]["id"]
    assert_equal "Rent", json["data"]["title"]
  end

  test "show returns 404 for nonexistent" do
    get api_v1_banking_payment_reminder_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  test "create reminder" do
    assert_difference "PaymentReminder.count", 1 do
      post api_v1_banking_payment_reminders_path,
        params: {
          payment_reminder: {
            title: "Electric Bill",
            expected_amount: 80.00,
            cutoff_date: (Date.current + 20.days).to_s,
            active: true,
            reminder_days_before: [ 5, 1 ]
          }
        },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Electric Bill", json["data"]["title"]
  end

  test "update reminder" do
    patch api_v1_banking_payment_reminder_path(@reminder),
      params: { payment_reminder: { expected_amount: 1300.00 } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1300.0, json["data"]["expected_amount"]
  end

  test "destroy reminder" do
    assert_difference "PaymentReminder.count", -1 do
      delete api_v1_banking_payment_reminder_path(@reminder), headers: @auth_header
    end

    assert_response :ok
  end

  test "clone creates new reminder from existing" do
    assert_difference "PaymentReminder.count", 1 do
      post clone_api_v1_banking_payment_reminder_path(@reminder), headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Rent", json["data"]["title"]
    assert_equal 1200.0, json["data"]["expected_amount"]
    assert_not_equal @reminder.id, json["data"]["id"]
  end

  test "returns 401 without auth" do
    get api_v1_banking_payment_reminders_path

    assert_response :unauthorized
  end
end
