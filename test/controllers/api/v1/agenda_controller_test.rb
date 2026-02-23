require "test_helper"

class Api::V1::AgendaControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "apiagendashow@example.com",
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

  # === SHOW ===

  test "show returns empty array when no posts" do
    get api_v1_agenda_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal [], json["data"]
  end

  test "show returns latest post of each type" do
    # Create older appointment
    AgendaPost::Appointment.create!(
      user: @user,
      data: {
        "entries" => [
          {
            "start_time" => "2024-02-04T09:00:00Z",
            "end_time" => "2024-02-04T10:00:00Z",
            "title" => "Old meeting"
          }
        ]
      }
    )

    # Create newer appointment
    newer_appointment = AgendaPost::Appointment.create!(
      user: @user,
      data: {
        "entries" => [
          {
            "start_time" => "2024-02-04T14:00:00Z",
            "end_time" => "2024-02-04T15:00:00Z",
            "title" => "New meeting"
          }
        ]
      }
    )

    # Create study plan
    study_plan = AgendaPost::StudyPlan.create!(
      user: @user,
      data: {
        "entries" => [
          {
            "subject" => "Math",
            "title" => "Chapter 5"
          }
        ]
      }
    )

    get api_v1_agenda_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)

    # Should return 2 posts (one of each type)
    assert_equal 2, json["data"].length

    types = json["data"].map { |p| p["type"] }
    assert_includes types, "appointment"
    assert_includes types, "study_plan"

    # The appointment should be the newer one
    appointment_data = json["data"].find { |p| p["type"] == "appointment" }
    assert_equal newer_appointment.id, appointment_data["id"]
    assert_equal "New meeting", appointment_data["data"]["entries"][0]["title"]
  end

  test "show only returns current user's posts" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + %w[api agenda]
    )

    # Create post for other user
    AgendaPost::Appointment.create!(
      user: other_user,
      data: {
        "entries" => [
          {
            "start_time" => "2024-02-04T09:00:00Z",
            "end_time" => "2024-02-04T10:00:00Z",
            "title" => "Other user meeting"
          }
        ]
      }
    )

    get api_v1_agenda_path, headers: @auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal [], json["data"]
  end

  # === AUTHORIZATION ===

  test "requires authentication" do
    get api_v1_agenda_path
    assert_response :unauthorized
  end

  test "returns 403 without agenda role" do
    user_no_agenda = User.create!(
      email: "noagenda2@example.com",
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

    get api_v1_agenda_path, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :forbidden
  end
end
