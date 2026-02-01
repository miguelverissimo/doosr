require "test_helper"

class Api::V1::JournalsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apijournals@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + %w[api journals]
    )
    @plain_token = ApiToken.generate_token
    @user.api_tokens.create!(
      name: "Test Token",
      token_digest: ApiToken.digest_token(@plain_token),
      token_prefix: @plain_token[0..11]
    )
    @auth_header = { "Authorization" => "Bearer #{@plain_token}" }

    @journal = @user.journals.create!(date: Date.parse("2025-06-15"))

    @fragment = @user.journal_fragments.create!(
      journal: @journal,
      content: "Today was a good day"
    )

    @prompt = @user.journal_prompts.create!(
      journal: @journal,
      prompt_text: "What are you grateful for?"
    )
  end

  # === INDEX ===

  test "index returns journals with pagination" do
    get api_v1_journals_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["data"].is_a?(Array)
    assert_equal 1, json["meta"]["total_count"]
    assert_equal 1, json["meta"]["page"]
  end

  test "index supports search by date" do
    get api_v1_journals_path(search: "2025-06"), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json["data"].length

    get api_v1_journals_path(search: "2024-01"), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 0, json["data"].length
  end

  test "index returns journal summary without content" do
    get api_v1_journals_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    journal_data = json["data"].first
    assert_equal @journal.id, journal_data["id"]
    assert_equal "2025-06-15", journal_data["date"]
    assert journal_data.key?("date_display")
    assert_not journal_data.key?("fragments")
    assert_not journal_data.key?("prompts")
  end

  # === SHOW ===

  test "show returns journal with fragments and prompts" do
    get api_v1_journal_path(@journal), headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @journal.id, json["data"]["id"]
    assert_equal "2025-06-15", json["data"]["date"]

    # Fragments
    assert json["data"]["fragments"].is_a?(Array)
    assert_equal 1, json["data"]["fragments"].length
    assert_equal "Today was a good day", json["data"]["fragments"].first["content"]

    # Prompts
    assert json["data"]["prompts"].is_a?(Array)
    assert_equal 1, json["data"]["prompts"].length
    assert_equal "What are you grateful for?", json["data"]["prompts"].first["prompt_text"]
  end

  test "show returns 404 for nonexistent journal" do
    get api_v1_journal_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  # === CREATE ===

  test "create journal for a new date" do
    assert_difference "Journal.count", 1 do
      post api_v1_journals_path,
        params: { journal: { date: "2025-07-01" } },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "2025-07-01", json["data"]["date"]
    assert json["data"].key?("fragments")
    assert json["data"].key?("prompts")
  end

  test "create journal fails with duplicate date" do
    post api_v1_journals_path,
      params: { journal: { date: "2025-06-15" } },
      headers: @auth_header

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].any?
  end

  test "create journal fails without date" do
    post api_v1_journals_path,
      params: { journal: { date: "" } },
      headers: @auth_header

    assert_response :unprocessable_entity
  end

  # === DESTROY ===

  test "destroy journal" do
    assert_difference "Journal.count", -1 do
      delete api_v1_journal_path(@journal), headers: @auth_header
    end

    assert_response :ok
  end

  test "destroy nonexistent journal returns 404" do
    delete api_v1_journal_path(id: 999999), headers: @auth_header

    assert_response :not_found
  end

  # === AUTHORIZATION ===

  test "returns 401 without auth token" do
    get api_v1_journals_path

    assert_response :unauthorized
  end

  test "returns 403 without journals role" do
    user_no_journals = User.create!(
      email: "nojournals@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: %w[day api]
    )
    token = ApiToken.generate_token
    user_no_journals.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(token),
      token_prefix: token[0..11]
    )

    get api_v1_journals_path,
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end
end
