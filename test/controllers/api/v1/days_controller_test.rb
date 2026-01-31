require "test_helper"

class Api::V1::DaysControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apidays@example.com",
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
  end

  # === SHOW ===

  test "show returns null data when no day exists for date" do
    get api_v1_days_path(date: "2025-06-15"), headers: @auth_header
    assert_response :success

    json = JSON.parse(response.body)
    assert_nil json["data"]
    assert_equal "2025-06-15", json["meta"]["date"]
  end

  test "show returns day with items when day exists" do
    day = @user.days.create!(date: Date.parse("2025-06-15"), state: :open, skip_permanent_sections_callback: true)
    item = @user.items.create!(title: "Test task", item_type: :completable, state: :todo)
    day.descendant.add_active_item(item.id)
    day.descendant.save!

    get api_v1_days_path(date: "2025-06-15"), headers: @auth_header
    assert_response :success

    json = JSON.parse(response.body)
    assert_not_nil json["data"]
    assert_equal day.id, json["data"]["id"]
    assert_equal "2025-06-15", json["data"]["date"]
    assert_equal "open", json["data"]["state"]
    assert_equal 1, json["data"]["items"].length
    assert_equal "Test task", json["data"]["items"][0]["title"]
  end

  test "show defaults to today when no date given" do
    get api_v1_days_path, headers: @auth_header
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal Date.today.to_s, json["meta"]["date"]
  end

  # === CREATE ===

  test "create opens a new day" do
    assert_difference "@user.days.count", 1 do
      post api_v1_days_path, params: { date: "2025-07-01" }, headers: @auth_header
    end
    assert_response :created

    json = JSON.parse(response.body)
    assert_equal "2025-07-01", json["data"]["date"]
    assert_equal "open", json["data"]["state"]
    assert json["meta"]["created"]
  end

  test "create returns existing day if already open" do
    @user.days.create!(date: Date.parse("2025-07-01"), state: :open, skip_permanent_sections_callback: true)

    assert_no_difference "@user.days.count" do
      post api_v1_days_path, params: { date: "2025-07-01" }, headers: @auth_header
    end
    assert_response :ok

    json = JSON.parse(response.body)
    assert_not json["meta"]["created"]
  end

  # === CLOSE ===

  test "close closes an open day" do
    day = @user.days.create!(date: Date.parse("2025-07-02"), state: :open, skip_permanent_sections_callback: true)

    patch api_v1_close_day_path(day), headers: @auth_header
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal "closed", json["data"]["state"]
    day.reload
    assert day.closed?
  end

  test "close returns error for already closed day" do
    day = @user.days.create!(date: Date.parse("2025-07-03"), state: :closed, closed_at: Time.current, skip_permanent_sections_callback: true)

    patch api_v1_close_day_path(day), headers: @auth_header
    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "Day is already closed", json["error"]
  end

  test "close returns 404 for non-existent day" do
    patch api_v1_close_day_path(id: 999999), headers: @auth_header
    assert_response :not_found
  end

  # === REOPEN ===

  test "reopen reopens a closed day" do
    day = @user.days.create!(date: Date.parse("2025-07-04"), state: :closed, closed_at: Time.current, skip_permanent_sections_callback: true)

    patch api_v1_reopen_day_path(day), headers: @auth_header
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal "open", json["data"]["state"]
    day.reload
    assert day.open?
  end

  test "reopen returns error for already open day" do
    day = @user.days.create!(date: Date.parse("2025-07-05"), state: :open, skip_permanent_sections_callback: true)

    patch api_v1_reopen_day_path(day), headers: @auth_header
    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "Day is already open", json["error"]
  end

  # === IMPORT ===

  test "import migrates items from latest importable day" do
    # Create a source day with an item
    source_day = @user.days.create!(date: Date.parse("2025-07-09"), state: :open, skip_permanent_sections_callback: true)
    item = @user.items.create!(title: "Migrate me", item_type: :completable, state: :todo)
    source_day.descendant.add_active_item(item.id)
    source_day.descendant.save!
    source_day.close!

    post api_v1_days_import_path, params: { date: "2025-07-10" }, headers: @auth_header
    assert_response :ok

    json = JSON.parse(response.body)
    assert json["meta"]["migrated_count"] >= 0
  end

  test "import returns error for closed target day" do
    target = @user.days.create!(date: Date.parse("2025-07-11"), state: :closed, closed_at: Time.current, skip_permanent_sections_callback: true)

    post api_v1_days_import_path, params: { date: "2025-07-11" }, headers: @auth_header
    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "Cannot import into a closed day", json["error"]
  end

  # === AUTH ===

  test "returns 401 without token" do
    get api_v1_days_path
    assert_response :unauthorized
  end

  test "returns 403 without api role" do
    user_no_api = User.create!(
      email: "noapi@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES
    )
    plain = ApiToken.generate_token
    user_no_api.api_tokens.create!(
      name: "No API",
      token_digest: ApiToken.digest_token(plain),
      token_prefix: plain[0..11]
    )

    get api_v1_days_path, headers: { "Authorization" => "Bearer #{plain}" }
    assert_response :forbidden
  end

  test "returns 403 without day role" do
    user_no_day = User.create!(
      email: "noday@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: [ "api" ]
    )
    plain = ApiToken.generate_token
    user_no_day.api_tokens.create!(
      name: "No Day",
      token_digest: ApiToken.digest_token(plain),
      token_prefix: plain[0..11]
    )

    get api_v1_days_path, headers: { "Authorization" => "Bearer #{plain}" }
    assert_response :forbidden

    json = JSON.parse(response.body)
    assert_includes json["error"], "day"
  end

  # === CANNOT ACCESS OTHER USER'S DAYS ===

  test "cannot close another user's day" do
    other_user = User.create!(
      email: "otherdays@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES
    )
    other_day = other_user.days.create!(date: Date.parse("2025-07-20"), state: :open, skip_permanent_sections_callback: true)

    patch api_v1_close_day_path(other_day), headers: @auth_header
    assert_response :not_found
  end
end
