require "test_helper"

class Api::V1::AgendaPostsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apiagenda@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + %w[api agenda]
    )
    @plain_token = ApiToken.generate_token
    @user.api_tokens.create!(
      name: "Test Token",
      token_digest: ApiToken.digest_token(@plain_token),
      token_prefix: @plain_token[0..11]
    )
    @auth_header = { "Authorization" => "Bearer #{@plain_token}" }
  end

  # === CREATE ===

  test "create appointment" do
    assert_difference "AgendaPost.count", 1 do
      post api_v1_agenda_posts_path,
        params: {
          type: "appointment",
          data: {
            entries: [
              {
                start_time: "2024-02-04T09:00:00Z",
                end_time: "2024-02-04T10:00:00Z",
                title: "Team standup",
                calendar: "Work"
              }
            ]
          }
        },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "appointment", json["data"]["type"]
    assert_equal 1, json["data"]["data"]["entries"].length
    assert_equal "Team standup", json["data"]["data"]["entries"][0]["title"]
  end

  test "create study_plan" do
    assert_difference "AgendaPost.count", 1 do
      post api_v1_agenda_posts_path,
        params: {
          type: "study_plan",
          data: {
            entries: [
              {
                subject: "Mathematics",
                title: "Chapter 5 review",
                url: "https://example.com/math"
              }
            ]
          }
        },
        headers: @auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "study_plan", json["data"]["type"]
    assert_equal "Mathematics", json["data"]["data"]["entries"][0]["subject"]
  end

  test "create with invalid type" do
    post api_v1_agenda_posts_path,
      params: {
        type: "invalid_type",
        data: { entries: [] }
      },
      headers: @auth_header

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_includes json["error"], "Invalid type"
  end

  test "create with invalid appointment data" do
    post api_v1_agenda_posts_path,
      params: {
        type: "appointment",
        data: {
          entries: [
            { title: "Missing times" }
          ]
        }
      },
      headers: @auth_header

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].any? { |e| e.include?("start_time") }
  end

  test "create with invalid study_plan data" do
    post api_v1_agenda_posts_path,
      params: {
        type: "study_plan",
        data: {
          entries: [
            { title: "Missing subject" }
          ]
        }
      },
      headers: @auth_header

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].any? { |e| e.include?("subject") }
  end

  # === AUTHORIZATION ===

  test "requires authentication" do
    post api_v1_agenda_posts_path,
      params: { type: "appointment", data: { entries: [] } }
    assert_response :unauthorized
  end

  test "returns 403 without agenda role" do
    user_no_agenda = User.create!(
      email: "noagenda@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: [ "api" ]
    )
    token = ApiToken.generate_token
    user_no_agenda.api_tokens.create!(
      name: "Test",
      token_digest: ApiToken.digest_token(token),
      token_prefix: token[0..11]
    )

    post api_v1_agenda_posts_path,
      params: { type: "appointment", data: { entries: [] } },
      headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
  end

  test "returns 403 when token scope does not include agenda" do
    scoped_token = ApiToken.generate_token
    @user.api_tokens.create!(
      name: "Scoped Token",
      token_digest: ApiToken.digest_token(scoped_token),
      token_prefix: scoped_token[0..11],
      scopes: [ "day" ]  # agenda not included
    )

    post api_v1_agenda_posts_path,
      params: { type: "appointment", data: { entries: [] } },
      headers: { "Authorization" => "Bearer #{scoped_token}" }
    assert_response :forbidden
  end
end
