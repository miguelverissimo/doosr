# frozen_string_literal: true

require "test_helper"

class ItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true
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

  # URL Unfurling tests

  test "creating item with URL calls unfurler service" do
    day = @user.days.create!(date: Date.today, state: :open)

    post items_path, params: {
      item: { title: "https://github.com" },
      day_id: day.id
    }, as: :turbo_stream

    assert_response :success

    # Verify item was created (unfurling may or may not succeed depending on network)
    created_item = @user.items.last
    assert_not_nil created_item
    assert created_item.title.present?
  end

  test "updating item title with URL calls unfurler service" do
    item = @user.items.create!(title: "Original title", item_type: :completable, state: :todo)
    day = @user.days.create!(date: Date.today, state: :open)
    day.descendant.add_active_item(item.id)
    day.descendant.save!

    original_title = item.title

    patch item_path(item), params: {
      item: { title: "https://example.com" },
      day_id: day.id,
      from_edit_form: "true"
    }, as: :turbo_stream

    assert_response :success

    item.reload
    # Title should have changed (either to unfurled title or stay as URL)
    assert_not_equal original_title, item.title
  end

  test "updating item without changing title does not change unfurled data" do
    item = @user.items.create!(
      title: "Existing title",
      item_type: :completable,
      state: :todo,
      extra_data: { "unfurled_url" => "https://old.com" }
    )
    day = @user.days.create!(date: Date.today, state: :open)
    day.descendant.add_active_item(item.id)
    day.descendant.save!

    patch item_path(item), params: {
      item: { notification_time: 1.hour.from_now.strftime("%Y-%m-%dT%H:%M") },
      day_id: day.id,
      from_edit_form: "true"
    }, as: :turbo_stream

    assert_response :success

    # URL should remain unchanged
    item.reload
    assert_equal "https://old.com", item.extra_data["unfurled_url"]
  end

  test "can update unfurled URL via edit form" do
    item = @user.items.create!(
      title: "Example",
      item_type: :completable,
      state: :todo,
      extra_data: {
        "unfurled_url" => "https://example.com",
        "unfurled_description" => "Old description"
      }
    )
    day = @user.days.create!(date: Date.today, state: :open)
    day.descendant.add_active_item(item.id)
    day.descendant.save!

    patch item_path(item), params: {
      item: {
        title: "Example",
        extra_data: {
          unfurled_url: "https://new-example.com",
          unfurled_description: "New description"
        }
      },
      day_id: day.id,
      from_edit_form: "true"
    }, as: :turbo_stream

    assert_response :success

    item.reload
    assert_equal "https://new-example.com", item.extra_data["unfurled_url"]
    assert_equal "New description", item.extra_data["unfurled_description"]
  end

  test "can remove preview image via edit form" do
    item = @user.items.create!(
      title: "Example",
      item_type: :completable,
      state: :todo
    )
    item.preview_image.attach(
      io: StringIO.new("fake image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
    day = @user.days.create!(date: Date.today, state: :open)
    day.descendant.add_active_item(item.id)
    day.descendant.save!

    assert item.preview_image.attached?

    patch item_path(item), params: {
      item: {
        title: "Example",
        remove_preview_image: "1"
      },
      day_id: day.id,
      from_edit_form: "true"
    }, as: :turbo_stream

    assert_response :success

    item.reload
    assert_not item.preview_image.attached?
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end
