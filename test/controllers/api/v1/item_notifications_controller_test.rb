require "test_helper"

class Api::V1::ItemNotificationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apinotif@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + [ "api" ]
    )
    @plain_token = ApiToken.generate_token
    @user.api_tokens.create!(
      name: "Test Token",
      token_digest: ApiToken.digest_token(@plain_token),
      token_prefix: @plain_token[0..11]
    )
    @auth_header = { "Authorization" => "Bearer #{@plain_token}" }

    @day = @user.days.create!(date: Date.parse("2025-06-15"), state: :open, skip_permanent_sections_callback: true)
    @item = @user.items.create!(title: "Task with reminders", item_type: :completable, state: :todo)
    @day.descendant.add_active_item(@item.id)
    @day.descendant.save!
  end

  # === INDEX ===

  test "list notifications for an item" do
    @user.notifications.create!(item: @item, remind_at: 1.hour.from_now, status: "pending", channels: [ "push", "in_app" ])
    @user.notifications.create!(item: @item, remind_at: 2.hours.from_now, status: "pending", channels: [ "push", "in_app" ])

    get api_v1_item_notifications_path(@item), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json["data"].size
    assert_equal 2, json["meta"]["total"]
  end

  test "list notifications returns empty for item with none" do
    get api_v1_item_notifications_path(@item), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 0, json["data"].size
  end

  test "list notifications excludes non-pending" do
    @user.notifications.create!(item: @item, remind_at: 1.hour.from_now, status: "pending", channels: [ "push", "in_app" ])
    sent = @user.notifications.create!(item: @item, remind_at: 1.hour.from_now, status: "pending", channels: [ "push", "in_app" ])
    sent.mark_sent!

    get api_v1_item_notifications_path(@item), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json["data"].size
  end

  # === CREATE ===

  test "create notification for an item" do
    remind_at = 1.hour.from_now.iso8601

    assert_difference "Notification.count", 1 do
      post api_v1_item_notifications_path(@item),
        params: { remind_at: remind_at },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal @item.id, json["data"]["item_id"]
    assert_equal "pending", json["data"]["status"]
    assert_equal [ "push", "in_app" ], json["data"]["channels"]
  end

  test "create notification fails with past date" do
    post api_v1_item_notifications_path(@item),
      params: { remind_at: 1.hour.ago.iso8601 },
      headers: @auth_header

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "create notification fails without remind_at" do
    post api_v1_item_notifications_path(@item),
      params: {},
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  test "create requires authentication" do
    post api_v1_item_notifications_path(@item),
      params: { remind_at: 1.hour.from_now.iso8601 }

    assert_response :unauthorized
  end

  # === DESTROY ===

  test "destroy notification" do
    notification = @user.notifications.create!(item: @item, remind_at: 1.hour.from_now, status: "pending", channels: [ "push", "in_app" ])

    assert_difference "Notification.count", -1 do
      delete api_v1_item_notification_path(@item, notification), headers: @auth_header
    end

    assert_response :ok
  end

  test "destroy notification fails for wrong item" do
    other_item = @user.items.create!(title: "Other task", item_type: :completable, state: :todo)
    notification = @user.notifications.create!(item: other_item, remind_at: 1.hour.from_now, status: "pending", channels: [ "push", "in_app" ])

    delete api_v1_item_notification_path(@item, notification), headers: @auth_header

    assert_response :unprocessable_entity
  end

  test "destroy returns not found for invalid id" do
    delete api_v1_item_notification_path(@item, id: 999999), headers: @auth_header
    assert_response :not_found
  end

  # === AUTHORIZATION ===

  test "returns 403 without day role" do
    user_no_day = User.create!(
      email: "nodaynotif@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: [ "api" ]
    )
    token = ApiToken.generate_token
    user_no_day.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(token),
      token_prefix: token[0..11]
    )

    get api_v1_item_notifications_path(@item),
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end

  test "returns not found for invalid item" do
    get api_v1_item_notifications_path(item_id: 999999), headers: @auth_header
    assert_response :not_found
  end
end
