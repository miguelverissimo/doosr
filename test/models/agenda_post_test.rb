require "test_helper"

class AgendaPostTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "agendatest@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + %w[api agenda]
    )
  end

  # === Base AgendaPost ===

  test "requires user" do
    post = AgendaPost::Appointment.new(data: { "entries" => [] })
    assert_not post.valid?
    assert_includes post.errors[:user], "must exist"
  end

  test "requires data" do
    post = AgendaPost::Appointment.new(user: @user, data: nil)
    assert_not post.valid?
    assert_includes post.errors[:data], "can't be blank"
  end

  test "data must have entries array" do
    post = AgendaPost::Appointment.new(user: @user, data: { "foo" => "bar" })
    assert_not post.valid?
    assert post.errors[:data].any? { |e| e.include?("entries") }
  end

  # === Appointment ===

  test "appointment validates required fields" do
    post = AgendaPost::Appointment.new(
      user: @user,
      data: {
        "entries" => [
          { "title" => "Meeting" }  # missing start_time and end_time
        ]
      }
    )
    assert_not post.valid?
    assert post.errors[:data].any? { |e| e.include?("start_time") }
    assert post.errors[:data].any? { |e| e.include?("end_time") }
  end

  test "appointment rejects unknown fields" do
    post = AgendaPost::Appointment.new(
      user: @user,
      data: {
        "entries" => [
          {
            "start_time" => "2024-02-04T09:00:00Z",
            "end_time" => "2024-02-04T10:00:00Z",
            "title" => "Meeting",
            "unknown_field" => "value"
          }
        ]
      }
    )
    assert_not post.valid?
    assert post.errors[:data].any? { |e| e.include?("unknown_field") }
  end

  test "appointment validates ISO8601 datetime format" do
    post = AgendaPost::Appointment.new(
      user: @user,
      data: {
        "entries" => [
          {
            "start_time" => "not-a-date",
            "end_time" => "2024-02-04T10:00:00Z",
            "title" => "Meeting"
          }
        ]
      }
    )
    assert_not post.valid?
    assert post.errors[:data].any? { |e| e.include?("ISO8601") }
  end

  test "appointment validates end_time after start_time" do
    post = AgendaPost::Appointment.new(
      user: @user,
      data: {
        "entries" => [
          {
            "start_time" => "2024-02-04T10:00:00Z",
            "end_time" => "2024-02-04T09:00:00Z",
            "title" => "Meeting"
          }
        ]
      }
    )
    assert_not post.valid?
    assert post.errors[:data].any? { |e| e.include?("end_time must be after start_time") }
  end

  test "appointment allows valid entry" do
    post = AgendaPost::Appointment.new(
      user: @user,
      data: {
        "entries" => [
          {
            "start_time" => "2024-02-04T09:00:00Z",
            "end_time" => "2024-02-04T10:00:00Z",
            "title" => "Team standup",
            "calendar" => "Work",
            "url" => "https://meet.google.com/abc"
          }
        ]
      }
    )
    assert post.valid?
    assert post.save
  end

  test "appointment allows multiple entries" do
    post = AgendaPost::Appointment.new(
      user: @user,
      data: {
        "entries" => [
          {
            "start_time" => "2024-02-04T09:00:00Z",
            "end_time" => "2024-02-04T10:00:00Z",
            "title" => "First meeting"
          },
          {
            "start_time" => "2024-02-04T14:00:00Z",
            "end_time" => "2024-02-04T15:00:00Z",
            "title" => "Second meeting"
          }
        ]
      }
    )
    assert post.valid?
    assert post.save
  end

  # === StudyPlan ===

  test "study_plan validates required fields" do
    post = AgendaPost::StudyPlan.new(
      user: @user,
      data: {
        "entries" => [
          { "title" => "Chapter 5" }  # missing subject
        ]
      }
    )
    assert_not post.valid?
    assert post.errors[:data].any? { |e| e.include?("subject") }
  end

  test "study_plan rejects unknown fields" do
    post = AgendaPost::StudyPlan.new(
      user: @user,
      data: {
        "entries" => [
          {
            "subject" => "Math",
            "title" => "Chapter 5",
            "unknown_field" => "value"
          }
        ]
      }
    )
    assert_not post.valid?
    assert post.errors[:data].any? { |e| e.include?("unknown_field") }
  end

  test "study_plan allows valid entry" do
    post = AgendaPost::StudyPlan.new(
      user: @user,
      data: {
        "entries" => [
          {
            "subject" => "Mathematics",
            "title" => "Chapter 5 review",
            "url" => "https://example.com/math"
          }
        ]
      }
    )
    assert post.valid?
    assert post.save
  end

  # === STI ===

  test "STI type is set correctly for Appointment" do
    post = AgendaPost::Appointment.create!(
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
    assert_equal "AgendaPost::Appointment", post.type
  end

  test "STI type is set correctly for StudyPlan" do
    post = AgendaPost::StudyPlan.create!(
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
    assert_equal "AgendaPost::StudyPlan", post.type
  end

  # === Association ===

  test "destroying user destroys agenda posts" do
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

    assert_difference "AgendaPost.count", -1 do
      @user.destroy
    end
  end
end
