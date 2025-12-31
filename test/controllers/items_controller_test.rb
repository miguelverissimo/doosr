# frozen_string_literal: true

require "test_helper"

class ItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    sign_in @user
  end

  test "CRITICAL: creating item on non-existent day creates day with permanent sections" do
    @user.permanent_sections = [ "Work", "Personal" ]
    @user.save!

    date = Date.tomorrow

    # Day doesn't exist yet
    assert_nil @user.days.find_by(date: date)

    # Create item on that date
    post items_path, params: {
      item: { title: "Test task", state: "todo" },
      date: date.to_s
    }, as: :turbo_stream

    # Day should be created
    day = @user.days.find_by(date: date)
    assert_not_nil day
    assert_equal "open", day.state

    # CRITICAL: Permanent sections should exist
    section_ids = day.descendant.extract_active_item_ids
    sections = Item.where(id: section_ids).sections
    section_titles = sections.map(&:title).sort

    assert_equal [ "Personal", "Work" ], section_titles
  end

  test "CRITICAL: creating item on closed day reopens day AND creates permanent sections" do
    @user.permanent_sections = [ "Work", "Personal" ]
    @user.save!

    date = Date.tomorrow

    # Create a closed day WITHOUT permanent sections
    day = @user.days.create!(
      date: date,
      state: :closed,
      closed_at: 1.hour.ago,
      skip_permanent_sections_callback: true
    )

    assert_equal "closed", day.state
    assert_equal 0, day.descendant.extract_active_item_ids.count

    # Create item on that closed day
    post items_path, params: {
      item: { title: "Test task", state: "todo" },
      date: date.to_s
    }, as: :turbo_stream

    assert_response :success

    # Day should be reopened
    day.reload
    assert_equal "open", day.state

    # CRITICAL: Permanent sections should be created
    section_ids = day.descendant.extract_active_item_ids.reject { |id| Item.find(id).title == "Test task" }
    sections = Item.where(id: section_ids).sections
    section_titles = sections.map(&:title).sort

    assert_equal [ "Personal", "Work" ], section_titles, "Permanent sections must be created when creating item on closed day"

    # CRITICAL: Response should contain turbo_stream updates for both header and items
    assert_match /turbo-stream.*action="update".*target="day_header"/, response.body, "Should update day header when day reopens"
    assert_match /turbo-stream.*action="update".*target="items_list"/, response.body, "Should update items list when sections are added"
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end
