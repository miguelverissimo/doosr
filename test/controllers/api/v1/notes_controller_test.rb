require "test_helper"

class Api::V1::NotesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apinotes@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + [ "api", "notes" ]
    )
    @plain_token = ApiToken.generate_token
    @user.api_tokens.create!(
      name: "Test Token",
      token_digest: ApiToken.digest_token(@plain_token),
      token_prefix: @plain_token[0..11]
    )
    @auth_header = { "Authorization" => "Bearer #{@plain_token}" }

    @note = @user.notes.create!(content: "Test note content")
  end

  # === INDEX ===

  test "index returns notes" do
    get api_v1_notes_path, headers: @auth_header
    assert_response :ok

    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert json["data"].length >= 1
    assert json["meta"]["total_count"] >= 1
  end

  test "index with search" do
    @user.notes.create!(content: "Unique searchable note xyz")

    get api_v1_notes_path(search: "xyz"), headers: @auth_header
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal 1, json["data"].length
    assert_includes json["data"][0]["content"], "xyz"
  end

  test "index with pagination" do
    get api_v1_notes_path(page: 1, per_page: 1), headers: @auth_header
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal 1, json["data"].length
    assert_equal 1, json["meta"]["page"]
    assert_equal 1, json["meta"]["per_page"]
  end

  # === SHOW ===

  test "show returns note" do
    get api_v1_note_path(@note), headers: @auth_header
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal @note.id, json["data"]["id"]
    assert_equal "Test note content", json["data"]["content"]
  end

  test "show returns not found" do
    get api_v1_note_path(id: 999999), headers: @auth_header
    assert_response :not_found
  end

  # === CREATE ===

  test "create a note" do
    assert_difference "Note.count", 1 do
      post api_v1_notes_path,
        params: { note: { content: "New note" } },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New note", json["data"]["content"]
  end

  test "create note attached to a day" do
    day = @user.days.create!(date: Date.parse("2025-06-15"), state: :open, skip_permanent_sections_callback: true)

    post api_v1_notes_path,
      params: { note: { content: "Day note" }, day_id: day.id },
      headers: @auth_header

    assert_response :created

    # Verify note is in day's descendant
    day.descendant.reload
    note_ids = day.descendant.extract_active_ids_by_type("Note")
    created_note = Note.find(JSON.parse(response.body)["data"]["id"])
    assert_includes note_ids, created_note.id
  end

  test "create fails without content" do
    post api_v1_notes_path,
      params: { note: { content: "" } },
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  # === UPDATE ===

  test "update note" do
    patch api_v1_note_path(@note),
      params: { note: { content: "Updated note" } },
      headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "Updated note", json["data"]["content"]
  end

  # === DESTROY ===

  test "destroy note" do
    assert_difference "Note.count", -1 do
      delete api_v1_note_path(@note), headers: @auth_header
    end

    assert_response :ok
  end

  # === AUTHORIZATION ===

  test "requires authentication" do
    get api_v1_notes_path
    assert_response :unauthorized
  end

  test "returns 403 without notes role" do
    user_no_notes = User.create!(
      email: "nonotes@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: [ "api" ]
    )
    token = ApiToken.generate_token
    user_no_notes.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(token),
      token_prefix: token[0..11]
    )

    get api_v1_notes_path, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
  end
end
