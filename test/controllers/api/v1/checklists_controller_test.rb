require "test_helper"

class Api::V1::ChecklistsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apichecklists@example.com",
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

    @checklist = @user.checklists.create!(
      name: "Morning Routine",
      description: "Daily morning checklist",
      kind: :template,
      flow: :sequential,
      items: [
        { "name" => "Wake up", "completed_at" => nil },
        { "name" => "Brush teeth", "completed_at" => nil },
        { "name" => "Exercise", "completed_at" => nil }
      ],
      metadata: {}
    )
  end

  # === INDEX ===

  test "index returns checklists" do
    get api_v1_checklists_path, headers: @auth_header
    assert_response :ok

    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert json["data"].length >= 1
  end

  # === SHOW ===

  test "show returns checklist with items" do
    get api_v1_checklist_path(@checklist), headers: @auth_header
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal @checklist.id, json["data"]["id"]
    assert_equal "Morning Routine", json["data"]["name"]
    assert_equal 3, json["data"]["items"].length
  end

  test "show returns not found" do
    get api_v1_checklist_path(id: 999999), headers: @auth_header
    assert_response :not_found
  end

  # === CREATE ===

  test "create a checklist" do
    assert_difference "Checklist.count", 1 do
      post api_v1_checklists_path,
        params: {
          checklist: {
            name: "New Checklist",
            description: "A new one",
            kind: "template",
            flow: "parallel"
          }
        },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Checklist", json["data"]["name"]
    assert_equal "parallel", json["data"]["flow"]
  end

  test "create fails without name" do
    post api_v1_checklists_path,
      params: { checklist: { name: "", description: "Missing name", kind: "template", flow: "sequential" } },
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  # === UPDATE ===

  test "update checklist" do
    patch api_v1_checklist_path(@checklist),
      params: { checklist: { name: "Updated Routine" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Updated Routine", json["data"]["name"]
  end

  # === DESTROY ===

  test "destroy checklist" do
    assert_difference "Checklist.count", -1 do
      delete api_v1_checklist_path(@checklist), headers: @auth_header
    end

    assert_response :ok
  end

  # === COMPLETE ITEM ===

  test "complete an item in checklist" do
    patch complete_item_api_v1_checklist_path(@checklist),
      params: { item_index: 0 },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"]["items"][0]["completed_at"].present?
    assert_nil json["data"]["items"][1]["completed_at"]
  end

  test "toggle completion off" do
    items = @checklist.items.dup
    items[0]["completed_at"] = Time.current.iso8601
    @checklist.update!(items: items)

    patch complete_item_api_v1_checklist_path(@checklist),
      params: { item_index: 0 },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_nil json["data"]["items"][0]["completed_at"]
  end

  test "complete item with invalid index" do
    patch complete_item_api_v1_checklist_path(@checklist),
      params: { item_index: 99 },
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  # === RESET ===

  test "reset checklist" do
    items = @checklist.items.dup
    items.each { |i| i["completed_at"] = Time.current.iso8601 }
    @checklist.update!(items: items, metadata: { "started_at" => Time.current.iso8601, "completed_at" => Time.current.iso8601 })

    post reset_api_v1_checklist_path(@checklist), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    json["data"]["items"].each do |item|
      assert_nil item["completed_at"]
    end
    assert_nil json["data"]["metadata"]["started_at"]
    assert_nil json["data"]["metadata"]["completed_at"]
  end

  # === AUTHORIZATION ===

  test "requires authentication" do
    get api_v1_checklists_path
    assert_response :unauthorized
  end

  test "returns 403 without checklists role" do
    user_no_cl = User.create!(
      email: "nocl@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: [ "api" ]
    )
    token = ApiToken.generate_token
    user_no_cl.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(token),
      token_prefix: token[0..11]
    )

    get api_v1_checklists_path, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
  end
end
