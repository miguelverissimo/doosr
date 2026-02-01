require "test_helper"

class Api::V1::ListItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apilistitems@example.com",
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

    @list = @user.lists.create!(title: "My List", slug: "test-listitems-slug", list_type: :private_list, visibility: :read_only)
    @item = @user.items.create!(title: "List item", item_type: :reusable, state: :todo)
    @list.descendant.add_active_item(@item.id)
    @list.descendant.save!
  end

  # === CREATE ===

  test "create reusable item in list" do
    assert_difference "Item.count", 1 do
      post api_v1_list_items_path(@list),
        params: { item: { title: "New reusable", item_type: "reusable" } },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New reusable", json["data"]["title"]
    assert_equal "reusable", json["data"]["item_type"]
  end

  test "create section in list" do
    post api_v1_list_items_path(@list),
      params: { item: { title: "Section Header", item_type: "section" } },
      headers: @auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "section", json["data"]["item_type"]
  end

  test "create rejects completable items in list" do
    post api_v1_list_items_path(@list),
      params: { item: { title: "Bad item", item_type: "completable" } },
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  test "create handles duplicate reusable item" do
    post api_v1_list_items_path(@list),
      params: { item: { title: "List item", item_type: "reusable" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["meta"]["duplicate"] || json["meta"]["reactivated"]
  end

  # === UPDATE ===

  test "update item in list" do
    patch api_v1_list_item_path(@list, @item),
      params: { item: { title: "Updated item" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Updated item", json["data"]["title"]
  end

  test "update rejects invalid item type" do
    patch api_v1_list_item_path(@list, @item),
      params: { item: { item_type: "completable" } },
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  # === DESTROY ===

  test "destroy item from list" do
    assert_difference "Item.count", -1 do
      delete api_v1_list_item_path(@list, @item), headers: @auth_header
    end

    assert_response :ok
  end

  # === TOGGLE STATE ===

  test "toggle state on list item" do
    patch toggle_state_api_v1_list_item_path(@list, @item),
      params: { state: "done" },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "done", json["data"]["state"]
  end

  # === MOVE ===

  test "move item in list" do
    item2 = @user.items.create!(title: "Second item", item_type: :reusable, state: :todo)
    @list.descendant.add_active_item(item2.id)
    @list.descendant.save!

    patch move_api_v1_list_item_path(@list, @item),
      params: { direction: "down" },
      headers: @auth_header

    assert_response :ok
  end

  # === REPARENT ===

  test "reparent item to section in list" do
    section = @user.items.create!(title: "Section", item_type: :section, state: :todo)
    @list.descendant.add_active_item(section.id)
    @list.descendant.save!

    patch reparent_api_v1_list_item_path(@list, @item),
      params: { target_item_id: section.id },
      headers: @auth_header

    assert_response :ok
  end

  # === AUTHORIZATION ===

  test "requires authentication" do
    post api_v1_list_items_path(@list),
      params: { item: { title: "Test", item_type: "reusable" } }
    assert_response :unauthorized
  end

  test "returns 403 without lists role" do
    user_no_lists = User.create!(
      email: "nolistsitems@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: [ "api" ]
    )
    token = ApiToken.generate_token
    user_no_lists.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(token),
      token_prefix: token[0..11]
    )

    post api_v1_list_items_path(@list),
      params: { item: { title: "Test", item_type: "reusable" } },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end
end
