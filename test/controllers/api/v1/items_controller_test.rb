require "test_helper"

class Api::V1::ItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apiitems@example.com",
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

    # Create a day with descendant for item tests
    @day = @user.days.create!(date: Date.parse("2025-06-15"), state: :open, skip_permanent_sections_callback: true)
    @item = @user.items.create!(title: "Existing task", item_type: :completable, state: :todo)
    @day.descendant.add_active_item(@item.id)
    @day.descendant.save!
  end

  # === CREATE ===

  test "create item in a day" do
    assert_difference "Item.count", 1 do
      post api_v1_items_path,
        params: { item: { title: "New task", item_type: "completable" }, day_id: @day.id },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New task", json["data"]["title"]
    assert_equal "completable", json["data"]["item_type"]
    assert_equal "todo", json["data"]["state"]
  end

  test "create item as nested child of another item" do
    assert_difference "Item.count", 1 do
      post api_v1_items_path,
        params: { item: { title: "Child task", item_type: "completable" }, parent_item_id: @item.id },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Child task", json["data"]["title"]

    # Verify parent item has a descendant with the child
    @item.reload
    assert @item.descendant.present?
  end

  test "create item fails without title" do
    post api_v1_items_path,
      params: { item: { title: "", item_type: "completable" }, day_id: @day.id },
      headers: @auth_header

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "create requires authentication" do
    post api_v1_items_path, params: { item: { title: "Test", item_type: "completable" } }
    assert_response :unauthorized
  end

  # === UPDATE ===

  test "update item title" do
    patch api_v1_item_path(@item),
      params: { item: { title: "Updated task" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Updated task", json["data"]["title"]
    assert_equal @item.id, json["data"]["id"]
  end

  test "update returns not found for invalid id" do
    patch api_v1_item_path(id: 999999),
      params: { item: { title: "Updated" } },
      headers: @auth_header

    assert_response :not_found
  end

  # === DESTROY ===

  test "destroy item" do
    assert_difference "Item.count", -1 do
      delete api_v1_item_path(@item), headers: @auth_header
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_nil json["data"]
  end

  test "destroy returns not found for invalid id" do
    delete api_v1_item_path(id: 999999), headers: @auth_header
    assert_response :not_found
  end

  # === TOGGLE STATE ===

  test "toggle state to done" do
    patch toggle_state_api_v1_item_path(@item),
      params: { state: "done" },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "done", json["data"]["state"]
  end

  test "toggle state to dropped" do
    patch toggle_state_api_v1_item_path(@item),
      params: { state: "dropped" },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "dropped", json["data"]["state"]
  end

  test "toggle state back to todo" do
    @item.set_done!
    patch toggle_state_api_v1_item_path(@item),
      params: { state: "todo" },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "todo", json["data"]["state"]
  end

  test "toggle state with invalid state" do
    patch toggle_state_api_v1_item_path(@item),
      params: { state: "invalid" },
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  # === MOVE ===

  test "move item down" do
    item2 = @user.items.create!(title: "Second task", item_type: :completable, state: :todo)
    @day.descendant.add_active_item(item2.id)
    @day.descendant.save!

    patch move_api_v1_item_path(@item),
      params: { direction: "down" },
      headers: @auth_header

    assert_response :ok
  end

  test "move item up fails when at top" do
    patch move_api_v1_item_path(@item),
      params: { direction: "up" },
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  # === DEFER ===

  test "defer item to a date" do
    patch defer_api_v1_item_path(@item),
      params: { target_date: (Date.today + 7).to_s },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "deferred", json["data"]["state"]
  end

  test "defer item to tomorrow shortcut" do
    patch defer_api_v1_item_path(@item),
      params: { target_date: "tomorrow" },
      headers: @auth_header

    assert_response :ok
  end

  test "defer with invalid date" do
    patch defer_api_v1_item_path(@item),
      params: { target_date: "not-a-date" },
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  # === UNDEFER ===

  test "undefer item" do
    @item.set_deferred!(Date.today + 7)

    patch undefer_api_v1_item_path(@item), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "todo", json["data"]["state"]
  end

  # === REPARENT ===

  test "reparent item to another item" do
    target = @user.items.create!(title: "Target section", item_type: :section, state: :todo)
    @day.descendant.add_active_item(target.id)
    @day.descendant.save!

    patch reparent_api_v1_item_path(@item),
      params: { target_item_id: target.id },
      headers: @auth_header

    assert_response :ok
  end

  # === DROP SECTION ===

  test "drop section" do
    section = @user.items.create!(title: "My Section", item_type: :section, state: :todo)
    @day.descendant.add_active_item(section.id)
    @day.descendant.save!

    patch drop_section_api_v1_item_path(section), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "dropped", json["data"]["state"]
  end

  test "drop section fails for non-section" do
    patch drop_section_api_v1_item_path(@item), headers: @auth_header
    assert_response :unprocessable_entity
  end

  # === UPDATE RECURRENCE ===

  test "update recurrence rule" do
    rule = { "frequency" => "daily", "interval" => 1 }
    patch update_recurrence_api_v1_item_path(@item),
      params: { recurrence_rule: rule.to_json },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"]["recurrence_rule"].present?
  end

  test "clear recurrence rule" do
    @item.update!(recurrence_rule: { "frequency" => "daily" }.to_json)

    patch update_recurrence_api_v1_item_path(@item),
      params: { recurrence_rule: "none" },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_nil json["data"]["recurrence_rule"]
  end

  # === AUTHORIZATION ===

  test "returns 403 without day role" do
    user_no_day = User.create!(
      email: "noday@example.com",
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

    post api_v1_items_path,
      params: { item: { title: "Test", item_type: "completable" } },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end
end
