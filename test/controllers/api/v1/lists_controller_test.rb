require "test_helper"

class Api::V1::ListsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apilists@example.com",
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

    @list = @user.lists.create!(title: "My List", slug: "test-list-slug", list_type: :private_list, visibility: :read_only)
  end

  # === INDEX ===

  test "index returns all lists" do
    get api_v1_lists_path, headers: @auth_header
    assert_response :ok

    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert json["data"].length >= 1
    assert_equal @list.id, json["data"][0]["id"]
  end

  # === SHOW ===

  test "show returns list with items" do
    item = @user.items.create!(title: "List item", item_type: :reusable, state: :todo)
    @list.descendant.add_active_item(item.id)
    @list.descendant.save!

    get api_v1_list_path(@list), headers: @auth_header
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal @list.id, json["data"]["id"]
    assert_equal "My List", json["data"]["title"]
    assert_equal 1, json["data"]["items"].length
    assert_equal "List item", json["data"]["items"][0]["title"]
  end

  test "show returns not found for invalid id" do
    get api_v1_list_path(id: 999999), headers: @auth_header
    assert_response :not_found
  end

  # === CREATE ===

  test "create a list" do
    assert_difference "List.count", 1 do
      post api_v1_lists_path,
        params: { list: { title: "New List", slug: "new-list-#{SecureRandom.hex(4)}", list_type: "private_list", visibility: "read_only" } },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New List", json["data"]["title"]
    assert_equal "private_list", json["data"]["list_type"]
  end

  test "create fails without title" do
    post api_v1_lists_path,
      params: { list: { title: "", slug: "no-title-#{SecureRandom.hex(4)}", list_type: "private_list", visibility: "read_only" } },
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  # === UPDATE ===

  test "update list title" do
    patch api_v1_list_path(@list),
      params: { list: { title: "Updated List" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Updated List", json["data"]["title"]
  end

  # === DESTROY ===

  test "destroy list" do
    assert_difference "List.count", -1 do
      delete api_v1_list_path(@list), headers: @auth_header
    end

    assert_response :ok
  end

  # === AUTHORIZATION ===

  test "requires authentication" do
    get api_v1_lists_path
    assert_response :unauthorized
  end

  test "returns 403 without lists role" do
    user_no_lists = User.create!(
      email: "nolists@example.com",
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

    get api_v1_lists_path, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
  end
end
