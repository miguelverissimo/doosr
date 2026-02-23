require "test_helper"

class AgendaControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "agendaweb@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + [ "agenda" ]
    )
  end

  test "show requires authentication" do
    get agenda_path
    assert_redirected_to new_user_session_path
  end

  test "show requires agenda role" do
    user_no_agenda = User.create!(
      email: "noagenda@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES
    )

    sign_in user_no_agenda
    # CanCan raises RoutingError which results in 404
    get agenda_path
    assert_response :not_found
  end

  test "show renders page with no posts" do
    sign_in @user
    get agenda_path
    assert_response :ok
  end

  test "show renders page with posts" do
    sign_in @user

    AgendaPost::Appointment.create!(
      user: @user,
      data: {
        "entries" => [
          {
            "start_time" => "2024-02-04T09:00:00Z",
            "end_time" => "2024-02-04T10:00:00Z",
            "title" => "Meeting"
          }
        ]
      }
    )

    get agenda_path
    assert_response :ok
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end
