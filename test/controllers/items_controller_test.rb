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

  # Reminders action tests

  test "reminders action returns reminders section for item" do
    day = @user.days.create!(date: Date.today, state: :open)
    item = @user.items.create!(title: "Test item", item_type: :completable, state: :todo)
    day.descendant.add_active_item(item.id)
    day.descendant.save!

    get reminders_item_path(item, day_id: day.id), as: :turbo_stream

    assert_response :success
    assert_match /turbo-stream.*action="replace".*target="sheet_content_area"/, response.body
    assert_match /Reminders/, response.body
    assert_match /No reminders set/, response.body
  end

  test "reminders action shows pending reminders" do
    day = @user.days.create!(date: Date.today, state: :open)
    item = @user.items.create!(title: "Test item", item_type: :completable, state: :todo)
    day.descendant.add_active_item(item.id)
    day.descendant.save!

    # Create a pending reminder
    notification = @user.notifications.create!(
      item: item,
      remind_at: 2.hours.from_now,
      status: "pending",
      channels: [ "in_app" ]
    )

    get reminders_item_path(item, day_id: day.id), as: :turbo_stream

    assert_response :success
    assert_match /turbo-stream.*action="replace".*target="sheet_content_area"/, response.body
    assert_match notification.remind_at.strftime("%b %-d, %Y"), response.body
  end

  test "reminders action requires authentication" do
    sign_out

    item = @user.items.create!(title: "Test item", item_type: :completable, state: :todo)

    get reminders_item_path(item), as: :turbo_stream

    assert_response :redirect
  end

  # Reminder form action tests

  test "reminder_form action returns add reminder form" do
    day = @user.days.create!(date: Date.today, state: :open)
    item = @user.items.create!(title: "Test item", item_type: :completable, state: :todo)
    day.descendant.add_active_item(item.id)
    day.descendant.save!

    get reminder_form_item_path(item, day_id: day.id), as: :turbo_stream

    assert_response :success
    assert_match /turbo-stream.*action="replace".*target="sheet_content_area"/, response.body
    assert_match /Add Reminder/, response.body
    assert_match /datetime-local/, response.body
    assert_match /Save Reminder/, response.body
  end

  test "reminder_form action shows preset buttons" do
    day = @user.days.create!(date: Date.today, state: :open)
    item = @user.items.create!(title: "Test item", item_type: :completable, state: :todo)
    day.descendant.add_active_item(item.id)
    day.descendant.save!

    get reminder_form_item_path(item, day_id: day.id), as: :turbo_stream

    assert_response :success
    assert_match /In 1 hour/, response.body
    assert_match /Tomorrow 9am/, response.body
    assert_match /In 3 days/, response.body
  end

  test "reminder_form action requires authentication" do
    sign_out

    item = @user.items.create!(title: "Test item", item_type: :completable, state: :todo)

    get reminder_form_item_path(item), as: :turbo_stream

    assert_response :redirect
  end

  # Section creation tests

  test "creating section item sets correct item_type" do
    day = @user.days.create!(date: Date.today, state: :open)

    post items_path, params: {
      item: { title: "My Section", item_type: "section" },
      day_id: day.id
    }, as: :turbo_stream

    assert_response :success

    created_item = @user.items.find_by(title: "My Section")
    assert_not_nil created_item
    assert created_item.section?, "Item should be a section"
    assert_equal "todo", created_item.state
  end

  test "creating section item renders SectionItem component" do
    day = @user.days.create!(date: Date.today, state: :open)

    post items_path, params: {
      item: { title: "My Section", item_type: "section" },
      day_id: day.id
    }, as: :turbo_stream

    assert_response :success
    # SectionItem has bg-muted class and hash icon
    assert_match /bg-muted/, response.body
  end

  # Drop section tests

  test "drop_section drops section without children" do
    day = @user.days.create!(date: Date.today, state: :open)
    section = @user.items.create!(title: "Empty Section", item_type: :section, state: :todo)
    day.descendant.add_active_item(section.id)
    day.descendant.save!

    patch drop_section_item_path(section), params: {
      day_id: day.id,
      confirmed: "true"
    }, as: :turbo_stream

    assert_response :success

    section.reload
    assert section.dropped?, "Section should be dropped"
    assert_not_nil section.dropped_at
  end

  test "drop_section with children shows confirmation when not confirmed" do
    day = @user.days.create!(date: Date.today, state: :open)
    section = @user.items.create!(title: "Section with Children", item_type: :section, state: :todo)
    child_item = @user.items.create!(title: "Child Item", item_type: :completable, state: :todo)

    day.descendant.add_active_item(section.id)
    day.descendant.save!

    # Add child to section
    section.descendant.add_active_item(child_item.id)
    section.descendant.save!

    # Request without confirmation
    patch drop_section_item_path(section), params: {
      day_id: day.id
    }, as: :turbo_stream

    assert_response :success
    # Should show confirmation dialog
    assert_match /1 active item/, response.body
    assert_match /will also be dropped/, response.body

    # Section should NOT be dropped yet
    section.reload
    assert section.todo?, "Section should still be in todo state"
  end

  test "drop_section with children drops all when confirmed" do
    day = @user.days.create!(date: Date.today, state: :open)
    section = @user.items.create!(title: "Section with Children", item_type: :section, state: :todo)
    child_item1 = @user.items.create!(title: "Child Item 1", item_type: :completable, state: :todo)
    child_item2 = @user.items.create!(title: "Child Item 2", item_type: :completable, state: :todo)

    day.descendant.add_active_item(section.id)
    day.descendant.save!

    # Add children to section
    section.descendant.add_active_item(child_item1.id)
    section.descendant.add_active_item(child_item2.id)
    section.descendant.save!

    # Request with confirmation
    patch drop_section_item_path(section), params: {
      day_id: day.id,
      confirmed: "true"
    }, as: :turbo_stream

    assert_response :success

    # All items should be dropped
    section.reload
    child_item1.reload
    child_item2.reload

    assert section.dropped?, "Section should be dropped"
    assert child_item1.dropped?, "Child item 1 should be dropped"
    assert child_item2.dropped?, "Child item 2 should be dropped"
  end

  test "drop_section with nested children drops recursively" do
    day = @user.days.create!(date: Date.today, state: :open)
    section = @user.items.create!(title: "Parent Section", item_type: :section, state: :todo)
    nested_section = @user.items.create!(title: "Nested Section", item_type: :section, state: :todo)
    grandchild = @user.items.create!(title: "Grandchild Item", item_type: :completable, state: :todo)

    day.descendant.add_active_item(section.id)
    day.descendant.save!

    # Add nested section to parent section
    section.descendant.add_active_item(nested_section.id)
    section.descendant.save!

    # Add grandchild to nested section
    nested_section.descendant.add_active_item(grandchild.id)
    nested_section.descendant.save!

    # Request with confirmation
    patch drop_section_item_path(section), params: {
      day_id: day.id,
      confirmed: "true"
    }, as: :turbo_stream

    assert_response :success

    # All items should be dropped recursively
    section.reload
    nested_section.reload
    grandchild.reload

    assert section.dropped?, "Parent section should be dropped"
    assert nested_section.dropped?, "Nested section should be dropped"
    assert grandchild.dropped?, "Grandchild item should be dropped"
  end

  test "dropped section has muted appearance" do
    day = @user.days.create!(date: Date.today, state: :open)
    section = @user.items.create!(title: "Dropped Section", item_type: :section, state: :todo)
    day.descendant.add_active_item(section.id)
    day.descendant.save!

    # Drop the section
    section.set_section_dropped!

    # Reload day view
    get day_path(date: day.date.to_s)

    assert_response :success
    # Dropped section should have opacity-50 class
    assert_match /opacity-50/, response.body
  end

  # Nested items tests

  test "adding item to section updates drawer" do
    day = @user.days.create!(date: Date.today, state: :open)
    section = @user.items.create!(title: "My Section", item_type: :section, state: :todo)
    day.descendant.add_active_item(section.id)
    day.descendant.save!

    # Add nested item from drawer
    post items_path, params: {
      item: { title: "Nested Item", item_type: "completable" },
      parent_item_id: section.id,
      day_id: day.id
    }, as: :turbo_stream

    assert_response :success

    # Verify item was created and added to section
    nested_item = @user.items.find_by(title: "Nested Item")
    assert_not_nil nested_item

    # Reload section's descendant to get fresh data
    section.descendant.reload
    assert section.descendant.active_item?(nested_item.id), "Item should be in section's active items"

    # Response should append to nested_items container
    assert_match /turbo-stream.*action="append".*target="nested_items_#{section.id}"/, response.body
  end

  test "adding item to section updates day tree" do
    day = @user.days.create!(date: Date.today, state: :open)
    section = @user.items.create!(title: "My Section", item_type: :section, state: :todo)
    day.descendant.add_active_item(section.id)
    day.descendant.save!

    # Add nested item from drawer
    post items_path, params: {
      item: { title: "Nested Item", item_type: "completable" },
      parent_item_id: section.id,
      day_id: day.id
    }, as: :turbo_stream

    assert_response :success

    # Response should replace item_with_children in day tree
    assert_match /turbo-stream.*action="replace".*target="item_with_children_#{section.id}"/, response.body
  end

  test "adding first item to section shows nested items title" do
    day = @user.days.create!(date: Date.today, state: :open)
    section = @user.items.create!(title: "Empty Section", item_type: :section, state: :todo)
    day.descendant.add_active_item(section.id)
    day.descendant.save!

    # Ensure section has no children
    assert_equal 0, section.descendant.active_items.count

    # Add first nested item
    post items_path, params: {
      item: { title: "First Nested Item", item_type: "completable" },
      parent_item_id: section.id,
      day_id: day.id
    }, as: :turbo_stream

    assert_response :success

    # Response should update nested_items_title to show "Nested items" heading
    assert_match /turbo-stream.*action="update".*target="nested_items_title_#{section.id}"/, response.body
    assert_match /Nested items/, response.body
  end

  test "adding multiple items to section maintains order" do
    day = @user.days.create!(date: Date.today, state: :open)
    section = @user.items.create!(title: "My Section", item_type: :section, state: :todo)
    day.descendant.add_active_item(section.id)
    day.descendant.save!

    # Add first nested item
    post items_path, params: {
      item: { title: "First Item", item_type: "completable" },
      parent_item_id: section.id,
      day_id: day.id
    }, as: :turbo_stream

    # Add second nested item
    post items_path, params: {
      item: { title: "Second Item", item_type: "completable" },
      parent_item_id: section.id,
      day_id: day.id
    }, as: :turbo_stream

    section.descendant.reload
    active_item_ids = section.descendant.extract_active_item_ids
    items = Item.where(id: active_item_ids).index_by(&:id)

    # Items should be in order added
    assert_equal "First Item", items[active_item_ids[0]].title
    assert_equal "Second Item", items[active_item_ids[1]].title
  end

  private

  def sign_out
    delete destroy_user_session_path
  end

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end
