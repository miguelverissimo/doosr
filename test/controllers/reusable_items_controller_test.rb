# frozen_string_literal: true

require "test_helper"

class ReusableItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123", access_confirmed: true)
    @list = @user.lists.create!(title: "Test List", list_type: :private_list, slug: "test-list")

    # Descendant is automatically created by List after_create callback

    @item = @user.items.create!(title: "Test Item", item_type: :reusable, state: :todo)
    @list.reload # Reload to get the auto-created descendant
    @list.descendant.add_active_item(@item.id)
    @list.descendant.save!

    sign_in @user
  end

  test "should create reusable item with tuple format" do
    assert_difference("Item.count") do
      post reusable_items_path, params: {
        list_id: @list.id,
        item: { title: "New Item", item_type: "reusable", state: "todo" }
      }, as: :turbo_stream
    end

    assert_response :success

    # Verify item was added to descendant with tuple format
    @list.reload
    new_item = Item.last
    active_item_ids = @list.descendant.extract_active_item_ids
    assert_includes active_item_ids, new_item.id

    # Verify tuple format is maintained
    assert_includes @list.descendant.active_items, { "Item" => new_item.id }
  end

  test "should create section item with tuple format" do
    assert_difference("Item.count") do
      post reusable_items_path, params: {
        list_id: @list.id,
        item: { title: "New Section", item_type: "section", state: "todo" }
      }, as: :turbo_stream
    end

    assert_response :success

    # Verify section was added with tuple format
    @list.reload
    section = Item.last
    active_item_ids = @list.descendant.extract_active_item_ids
    assert_includes active_item_ids, section.id
    assert_includes @list.descendant.active_items, { "Item" => section.id }
  end

  test "should not create item with invalid type" do
    assert_no_difference("Item.count") do
      post reusable_items_path, params: {
        list_id: @list.id,
        item: { title: "Invalid Item", item_type: "completable", state: "todo" }
      }, as: :turbo_stream
    end

    assert_response :success
  end

  test "should detect duplicate items" do
    # Create an item
    existing_item = @user.items.create!(title: "Duplicate Test", item_type: :reusable, state: :todo)
    @list.descendant.add_active_item(existing_item.id)
    @list.descendant.save!

    # Try to create a duplicate (case insensitive)
    assert_no_difference("Item.count") do
      post reusable_items_path, params: {
        list_id: @list.id,
        item: { title: "duplicate test", item_type: "reusable", state: "todo" }
      }, as: :turbo_stream
    end

    assert_response :success
  end

  test "should reactivate inactive duplicate item" do
    # Create an item and mark it as done (moves to inactive)
    existing_item = @user.items.create!(title: "Reactivate Test", item_type: :reusable, state: :todo)
    @list.descendant.add_active_item(existing_item.id)
    @list.descendant.save!

    existing_item.set_done!
    @list.reload

    # Verify item is in inactive_items as tuple
    assert_includes @list.descendant.inactive_items, { "Item" => existing_item.id }
    refute_includes @list.descendant.active_items, { "Item" => existing_item.id }

    # Try to create same item again
    assert_no_difference("Item.count") do
      post reusable_items_path, params: {
        list_id: @list.id,
        item: { title: "Reactivate Test", item_type: "reusable", state: "todo" }
      }, as: :turbo_stream
    end

    assert_response :success

    # Verify item was moved back to active with tuple format
    @list.reload
    assert_includes @list.descendant.active_items, { "Item" => existing_item.id }
    refute_includes @list.descendant.inactive_items, { "Item" => existing_item.id }
  end

  test "should show actions sheet with correct position" do
    # Add more items to test position calculation
    item2 = @user.items.create!(title: "Item 2", item_type: :reusable, state: :todo)
    item3 = @user.items.create!(title: "Item 3", item_type: :reusable, state: :todo)

    @list.descendant.add_active_item(item2.id)
    @list.descendant.add_active_item(item3.id)
    @list.descendant.save!

    get actions_sheet_reusable_item_path(@item), params: { list_id: @list.id }, as: :turbo_stream

    assert_response :success
  end

  test "should toggle item state with tuple format" do
    patch toggle_state_reusable_item_path(@item), params: {
      state: "done",
      list_id: @list.id
    }, as: :turbo_stream

    assert_response :success

    @item.reload
    @list.reload

    assert_equal "done", @item.state

    # Verify item moved to inactive_items with tuple format
    assert_includes @list.descendant.inactive_items, { "Item" => @item.id }
    refute_includes @list.descendant.active_items, { "Item" => @item.id }
  end

  test "should move item up with tuple format" do
    # Add another item so we can move up
    item2 = @user.items.create!(title: "Item 2", item_type: :reusable, state: :todo)
    @list.descendant.add_active_item(item2.id)
    @list.descendant.save!

    # Verify initial order with tuples
    assert_equal [ { "Item" => @item.id }, { "Item" => item2.id } ], @list.descendant.active_items

    # Move item2 up
    patch move_reusable_item_path(item2), params: {
      direction: "up",
      list_id: @list.id
    }, as: :turbo_stream

    assert_response :success

    @list.reload

    # Verify order changed with tuples
    assert_equal [ { "Item" => item2.id }, { "Item" => @item.id } ], @list.descendant.active_items
  end

  test "should move item down with tuple format" do
    # Add another item so we can move down
    item2 = @user.items.create!(title: "Item 2", item_type: :reusable, state: :todo)
    @list.descendant.add_active_item(item2.id)
    @list.descendant.save!

    # Verify initial order with tuples
    assert_equal [ { "Item" => @item.id }, { "Item" => item2.id } ], @list.descendant.active_items

    # Move @item down
    patch move_reusable_item_path(@item), params: {
      direction: "down",
      list_id: @list.id
    }, as: :turbo_stream

    assert_response :success

    @list.reload

    # Verify order changed with tuples
    assert_equal [ { "Item" => item2.id }, { "Item" => @item.id } ], @list.descendant.active_items
  end

  test "should not move item beyond array bounds" do
    # Try to move first item up
    patch move_reusable_item_path(@item), params: {
      direction: "up",
      list_id: @list.id
    }, as: :turbo_stream

    assert_response :success

    @list.reload

    # Verify position unchanged
    assert_equal [ { "Item" => @item.id } ], @list.descendant.active_items
  end

  test "should update item" do
    patch reusable_item_path(@item), params: {
      list_id: @list.id,
      item: { title: "Updated Title" }
    }, as: :turbo_stream

    assert_response :success

    @item.reload
    assert_equal "Updated Title", @item.title
  end

  test "should show edit form" do
    get edit_form_reusable_item_path(@item), params: { list_id: @list.id }, as: :turbo_stream

    assert_response :success
  end

  test "should delete item without nested items" do
    assert_difference("Item.count", -1) do
      delete reusable_item_path(@item), params: {
        list_id: @list.id
      }, as: :turbo_stream
    end

    assert_response :success

    # Verify item removed from descendant
    @list.reload
    refute_includes @list.descendant.active_items, { "Item" => @item.id }
  end

  test "should delete item with nested items recursively" do
    # Create nested item
    nested_item = @user.items.create!(title: "Nested Item", item_type: :reusable, state: :todo)

    # Reload item to get auto-created descendant (if it's a section)
    @item.reload

    # Add nested item to descendant or create descendant if needed
    if @item.descendant
      @item.descendant.add_active_item(nested_item.id)
      @item.descendant.save!
    else
      Descendant.create!(descendable: @item, active_items: [ { "Item" => nested_item.id } ], inactive_items: [])
    end

    # Delete with confirmation
    assert_difference("Item.count", -2) do
      delete reusable_item_path(@item), params: {
        list_id: @list.id,
        confirmed: "true"
      }, as: :turbo_stream
    end

    assert_response :success

    # Verify both items deleted
    assert_not Item.exists?(@item.id)
    assert_not Item.exists?(nested_item.id)
  end

  test "should reparent item to list root" do
    # Create parent item (might auto-create descendant)
    parent_item = @user.items.create!(title: "Parent", item_type: :reusable, state: :todo)
    parent_item.reload

    # Create descendant if not auto-created
    unless parent_item.descendant
      Descendant.create!(descendable: parent_item, active_items: [], inactive_items: [])
      parent_item.reload
    end

    @list.descendant.add_active_item(parent_item.id)
    @list.descendant.save!

    nested_item = @user.items.create!(title: "Nested", item_type: :reusable, state: :todo)
    parent_item.descendant.add_active_item(nested_item.id)
    parent_item.descendant.save!

    # Reparent nested item to list root
    patch reparent_reusable_item_path(nested_item), params: {
      list_id: @list.id,
      target_item_id: ""
    }, as: :turbo_stream

    assert_response :success

    @list.reload
    parent_item.reload

    # Verify item moved to list root with tuple format
    assert_includes @list.descendant.active_items, { "Item" => nested_item.id }
    refute_includes parent_item.descendant.active_items, { "Item" => nested_item.id }
  end

  test "should reparent item to another item" do
    target_item = @user.items.create!(title: "Target", item_type: :reusable, state: :todo)
    @list.descendant.add_active_item(target_item.id)
    @list.descendant.save!

    # Reparent @item to target_item
    patch reparent_reusable_item_path(@item), params: {
      list_id: @list.id,
      target_item_id: target_item.id
    }, as: :turbo_stream

    assert_response :success

    @list.reload
    target_item.reload

    # Verify item moved from list root
    refute_includes @list.descendant.active_items, { "Item" => @item.id }

    # Verify item added to target with tuple format
    assert_not_nil target_item.descendant
    assert_includes target_item.descendant.active_items, { "Item" => @item.id }
  end

  test "should open debug sheet" do
    get debug_reusable_item_path(@item), params: { list_id: @list.id }, as: :turbo_stream

    assert_response :success
  end

  test "find_all_list_item_ids_recursively extracts IDs correctly" do
    # Create nested structure
    parent = @user.items.create!(title: "Parent", item_type: :section, state: :todo)
    child1 = @user.items.create!(title: "Child 1", item_type: :reusable, state: :todo)
    child2 = @user.items.create!(title: "Child 2", item_type: :reusable, state: :done)

    # Sections auto-create descendants, so reload to get it
    parent.reload

    # Add children to parent's descendant
    parent.descendant.add_active_item(child1.id)
    parent.descendant.add_inactive_item(child2.id)
    parent.descendant.save!

    @list.descendant.active_items = [ { "Item" => parent.id } ]
    @list.descendant.save!

    # Create a new controller instance to test the private method
    controller = ReusableItemsController.new
    controller.instance_variable_set(:@acting_user, @user)

    # Use send to call private method
    item_ids = controller.send(:find_all_list_item_ids_recursively, @list)

    # Verify all item IDs are extracted correctly (not tuples)
    assert_equal [ parent.id, child1.id, child2.id ].sort, item_ids.sort
    assert item_ids.all? { |id| id.is_a?(Integer) }
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end
