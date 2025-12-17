# frozen_string_literal: true

require "test_helper"

class Items::UndeferServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @today = Date.today
    @tomorrow = @today + 1.day

    # Create source day and item
    @source_day = @user.days.create!(date: @today, state: :open)
    @source_item = @user.items.create!(
      title: "Test Item",
      item_type: :completable,
      state: :deferred,
      deferred_at: Time.current,
      deferred_to: @tomorrow.to_time
    )
    @source_day.descendant.add_inactive_item(@source_item.id)
    @source_day.descendant.save!

    # Create target day and deferred copy
    @target_day = @user.days.create!(date: @tomorrow, state: :open)
    @deferred_copy = @user.items.create!(
      title: "Test Item",
      item_type: :completable,
      state: :todo,
      source_item: @source_item
    )
    @target_day.descendant.add_active_item(@deferred_copy.id)
    @target_day.descendant.save!
  end

  test "undefers deferred item back to todo" do
    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check source item state
    @source_item.reload
    assert_equal "todo", @source_item.state
    assert_nil @source_item.deferred_at
    assert_nil @source_item.deferred_to

    # Check source moved to active
    @source_day.reload
    assert @source_day.descendant.active_item?(@source_item.id)
    assert_not @source_day.descendant.inactive_item?(@source_item.id)
  end

  test "deletes deferred copy" do
    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    deferred_copy_id = @deferred_copy.id

    result = service.call

    assert result[:success]

    # Check deferred copy was deleted
    assert_nil Item.find_by(id: deferred_copy_id)
  end

  test "removes deferred copy from target descendant" do
    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check target day descendant no longer has the copy
    @target_day.reload
    assert_not @target_day.descendant.active_item?(@deferred_copy.id)
  end

  test "returns validation error for non-deferred item" do
    @source_item.update!(state: :todo, deferred_at: nil, deferred_to: nil)

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert_not result[:success]
    assert_includes result[:error], "Only deferred items can be undeferred"
  end

  test "returns validation error for done item" do
    @source_item.update!(state: :done, deferred_at: nil, deferred_to: nil)

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert_not result[:success]
    assert_includes result[:error], "Only deferred items can be undeferred"
  end

  test "handles item with no deferred copy gracefully" do
    # Delete the deferred copy
    @deferred_copy.destroy!

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    # Should still succeed and restore source to todo
    assert result[:success]

    @source_item.reload
    assert_equal "todo", @source_item.state
    assert_nil @source_item.deferred_at
  end

  test "deletes nested items recursively" do
    # Create nested structure in deferred copy
    @deferred_copy.create_descendant! unless @deferred_copy.descendant
    # Nested items should NOT have source_item - they're children of the deferred copy
    child1 = @user.items.create!(title: "Child 1", state: :todo)
    child2 = @user.items.create!(title: "Child 2", state: :todo)

    @deferred_copy.descendant.add_active_item(child1.id)
    @deferred_copy.descendant.add_active_item(child2.id)
    @deferred_copy.descendant.save!

    child1_id = child1.id
    child2_id = child2.id

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert result[:success], "Expected success but got error: #{result[:error]}"

    # Check all nested items were deleted
    assert_nil Item.find_by(id: child1_id)
    assert_nil Item.find_by(id: child2_id)
  end

  test "deletes multi-level nested tree recursively" do
    # Create 3-level nested structure
    @deferred_copy.create_descendant! unless @deferred_copy.descendant
    # Nested items should NOT have source_item - they're children of the deferred copy
    child = @user.items.create!(title: "Child", state: :todo)
    @deferred_copy.descendant.add_active_item(child.id)
    @deferred_copy.descendant.save!

    child.reload
    child.create_descendant! unless child.descendant
    grandchild = @user.items.create!(title: "Grandchild", state: :todo)
    child.descendant.add_active_item(grandchild.id)
    child.descendant.save!

    child_id = child.id
    grandchild_id = grandchild.id

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check entire tree was deleted
    assert_nil Item.find_by(id: child_id)
    assert_nil Item.find_by(id: grandchild_id)
  end

  test "raises error if multiple deferred copies found" do
    # Create a second deferred copy (should never happen)
    duplicate_copy = @user.items.create!(
      title: "Duplicate",
      item_type: :completable,
      state: :todo,
      source_item: @source_item
    )
    @target_day.descendant.add_active_item(duplicate_copy.id)
    @target_day.descendant.save!

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert_not result[:success]
    assert_includes result[:error], "Multiple deferred copies found"
  end

  # Transaction test removed - difficult to test without mocha/rspec mocking

  test "undefers item from nested position" do
    # Create parent item with deferred child
    parent = @user.items.create!(title: "Parent", state: :todo)
    @source_day.descendant.add_active_item(parent.id)
    @source_day.descendant.save!

    parent.reload
    parent.create_descendant! unless parent.descendant
    child = @user.items.create!(
      title: "Child",
      state: :deferred,
      deferred_at: Time.current,
      deferred_to: @tomorrow.to_time
    )
    parent.descendant.add_inactive_item(child.id)
    parent.descendant.save!

    # Create deferred copy
    child_copy = @user.items.create!(
      title: "Child",
      state: :todo,
      source_item: child
    )
    @target_day.descendant.add_active_item(child_copy.id)
    @target_day.descendant.save!

    # Undefer the child
    service = Items::UndeferService.new(
      source_item: child,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check child is back in parent's active items
    parent.reload
    assert parent.descendant.active_item?(child.id)
    assert_not parent.descendant.inactive_item?(child.id)

    # Check child state
    child.reload
    assert_equal "todo", child.state
  end

  test "deletes deferred copy even if modified by user" do
    # Modify the deferred copy
    @deferred_copy.update!(title: "Modified Title", extra_data: { "new" => "data" })

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check deferred copy was still deleted
    assert_nil Item.find_by(id: @deferred_copy.id)

    # Check source is back to todo with original title
    @source_item.reload
    assert_equal "todo", @source_item.state
    assert_equal "Test Item", @source_item.title
  end

  test "deletes deferred copy even if completed by user" do
    # Complete the deferred copy
    @deferred_copy.set_done!

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check deferred copy was still deleted
    assert_nil Item.find_by(id: @deferred_copy.id)
  end

  test "removes deferred copy from inactive items if user completed it" do
    # Complete the deferred copy (moves to inactive)
    @deferred_copy.set_done!

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check target day descendant no longer has the copy in any array
    @target_day.reload
    assert_not @target_day.descendant.active_item?(@deferred_copy.id)
    assert_not @target_day.descendant.inactive_item?(@deferred_copy.id)
  end

  test "handles section with nested items" do
    # Sections stay in todo state but have defer timestamps
    section = @user.items.create!(
      title: "Work Section",
      item_type: :section,
      state: :todo,
      deferred_at: Time.current,
      deferred_to: @tomorrow.to_time
    )
    @source_day.descendant.add_inactive_item(section.id)
    @source_day.descendant.save!

    # Create deferred copy with nested items
    section_copy = @user.items.create!(
      title: "Work Section",
      item_type: :section,
      state: :todo,
      source_item: section
    )
    @target_day.descendant.add_active_item(section_copy.id)
    @target_day.descendant.save!

    section_copy.reload
    section_copy.create_descendant! unless section_copy.descendant
    # Nested items should NOT have source_item - they're children of the deferred copy
    task = @user.items.create!(title: "Task", state: :todo)
    section_copy.descendant.add_active_item(task.id)
    section_copy.descendant.save!

    task_id = task.id

    service = Items::UndeferService.new(
      source_item: section,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check section is back to todo
    section.reload
    assert_equal "todo", section.state

    # Check entire tree (section and task) was deleted
    assert_nil Item.find_by(id: section_copy.id)
    assert_nil Item.find_by(id: task_id)
  end

  test "deletes items from both active and inactive arrays" do
    # Create deferred copy with mixed children
    @deferred_copy.create_descendant! unless @deferred_copy.descendant
    active_child = @user.items.create!(title: "Active", state: :todo)
    inactive_child = @user.items.create!(title: "Inactive", state: :done)

    @deferred_copy.descendant.add_active_item(active_child.id)
    @deferred_copy.descendant.add_inactive_item(inactive_child.id)
    @deferred_copy.descendant.save!

    active_child_id = active_child.id
    inactive_child_id = inactive_child.id

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check both children were deleted
    assert_nil Item.find_by(id: active_child_id)
    assert_nil Item.find_by(id: inactive_child_id)
  end

  test "preserves other items in target day descendant" do
    # Add another item to target day
    other_item = @user.items.create!(title: "Other Item", state: :todo)
    @target_day.descendant.add_active_item(other_item.id)
    @target_day.descendant.save!

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check other item is still in target day
    @target_day.reload
    assert @target_day.descendant.active_item?(other_item.id)

    # Check deferred copy was removed
    assert_not @target_day.descendant.active_item?(@deferred_copy.id)
  end

  test "preserves other items in source day descendant" do
    # Add another item to source day
    other_item = @user.items.create!(title: "Other Item", state: :todo)
    @source_day.descendant.add_active_item(other_item.id)
    @source_day.descendant.save!

    service = Items::UndeferService.new(
      source_item: @source_item,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check other item is still in source day
    @source_day.reload
    assert @source_day.descendant.active_item?(other_item.id)

    # Check source item moved to active
    assert @source_day.descendant.active_item?(@source_item.id)
  end
end
