# frozen_string_literal: true

require "test_helper"

class Items::CopyToDescendantServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @day = @user.days.create!(date: Date.today, state: :open)
    @target_descendant = @day.descendant

    # Create a source item with various attributes
    @source_item = @user.items.create!(
      title: "Test Item",
      item_type: :completable,
      state: :todo,
      extra_data: { "note" => "Test note", "tags" => [ "work" ] }
    )
  end

  test "copies item with all attributes to target descendant" do
    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user
    )

    result = service.call

    assert result[:success]
    assert_not_nil result[:new_item]

    new_item = result[:new_item]
    assert_equal @source_item.title, new_item.title
    assert_equal @source_item.item_type, new_item.item_type
    assert_equal @source_item.state, new_item.state
    assert_equal @source_item.extra_data, new_item.extra_data
    assert_equal @source_item.id, new_item.source_item_id
    assert_equal @user.id, new_item.user_id
  end

  test "adds todo item to target descendant active_items array" do
    @source_item.update!(state: :todo)

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user
    )

    result = service.call
    new_item = result[:new_item]

    @target_descendant.reload
    active_item_ids = @target_descendant.extract_active_item_ids

    assert_includes active_item_ids, new_item.id
  end

  test "adds done item to target descendant inactive_items array" do
    @source_item.update!(state: :done)

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user
    )

    result = service.call
    new_item = result[:new_item]

    @target_descendant.reload
    inactive_item_ids = @target_descendant.extract_inactive_item_ids

    assert_includes inactive_item_ids, new_item.id
  end

  test "adds dropped item to target descendant inactive_items array" do
    @source_item.update!(state: :dropped)

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user
    )

    result = service.call
    new_item = result[:new_item]

    @target_descendant.reload
    inactive_item_ids = @target_descendant.extract_inactive_item_ids

    assert_includes inactive_item_ids, new_item.id
  end

  test "adds deferred item to target descendant inactive_items array" do
    @source_item.update!(state: :deferred, deferred_to: 1.day.from_now)

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user
    )

    result = service.call
    new_item = result[:new_item]

    @target_descendant.reload
    inactive_item_ids = @target_descendant.extract_inactive_item_ids

    assert_includes inactive_item_ids, new_item.id
  end

  test "copies section item correctly" do
    section = @user.items.create!(
      title: "Section Title",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )

    service = Items::CopyToDescendantService.new(
      source_item: section,
      target_descendant: @target_descendant,
      user: @user
    )

    result = service.call
    new_item = result[:new_item]

    assert_equal "section", new_item.item_type
    assert_equal section.extra_data, new_item.extra_data
    assert_equal section.id, new_item.source_item_id
  end

  test "copies deferred attributes" do
    deferred_time = 2.days.from_now
    @source_item.update!(
      state: :deferred,
      deferred_at: Time.current,
      deferred_to: deferred_time
    )

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user
    )

    result = service.call
    new_item = result[:new_item]

    assert_not_nil new_item.deferred_at
    assert_equal deferred_time.to_i, new_item.deferred_to.to_i
  end

  test "copies recurrence_rule if present" do
    @source_item.update!(recurrence_rule: "FREQ=DAILY")

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user
    )

    result = service.call
    new_item = result[:new_item]

    assert_equal "FREQ=DAILY", new_item.recurrence_rule
  end

  test "returns success false on error" do
    # Force an error by using an invalid user
    invalid_user = User.new

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: invalid_user
    )

    result = service.call

    assert_not result[:success]
    assert_not_nil result[:error]
  end

  test "preserves extra_data as deep copy" do
    @source_item.update!(extra_data: { "nested" => { "value" => 123 } })

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user
    )

    result = service.call
    new_item = result[:new_item]

    assert_equal @source_item.extra_data, new_item.extra_data

    # Verify it's a copy, not a reference
    new_item.extra_data["nested"]["value"] = 456
    new_item.save!

    @source_item.reload
    assert_equal 123, @source_item.extra_data["nested"]["value"]
  end

  test "creates item with correct user association" do
    different_user = User.create!(
      email: "different@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: different_user
    )

    result = service.call
    new_item = result[:new_item]

    assert_equal different_user.id, new_item.user_id
  end

  test "adds item to end of active_items array" do
    # Add some existing items
    existing_item = @user.items.create!(title: "Existing", state: :todo)
    @target_descendant.add_active_item(existing_item.id)
    @target_descendant.save!

    initial_count = @target_descendant.extract_active_item_ids.length

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user
    )

    result = service.call
    new_item = result[:new_item]

    @target_descendant.reload
    active_item_ids = @target_descendant.extract_active_item_ids

    assert_equal initial_count + 1, active_item_ids.length
    assert_equal new_item.id, active_item_ids.last
  end

  test "copies item with nested children" do
    # Create source item with children
    @source_item.create_descendant! unless @source_item.descendant
    child1 = @user.items.create!(title: "Child 1", state: :todo)
    child2 = @user.items.create!(title: "Child 2", state: :todo)

    @source_item.descendant.add_active_item(child1.id)
    @source_item.descendant.add_active_item(child2.id)
    @source_item.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]
    assert_not_nil new_item.descendant

    new_child_ids = new_item.descendant.extract_active_item_ids
    assert_equal 2, new_child_ids.length

    # Verify children were copied with correct attributes
    new_children = Item.where(id: new_child_ids)
    assert_equal [ "Child 1", "Child 2" ], new_children.pluck(:title).sort

    # Verify source_item_id linkage
    assert_equal child1.id, new_children.find_by(title: "Child 1").source_item_id
    assert_equal child2.id, new_children.find_by(title: "Child 2").source_item_id
  end

  test "copies multi-level nested tree" do
    # Create 3-level tree:
    # source_item
    #   -> child1
    #      -> grandchild1
    #      -> grandchild2
    #   -> child2

    @source_item.create_descendant! unless @source_item.descendant
    child1 = @user.items.create!(title: "Child 1", state: :todo)
    child2 = @user.items.create!(title: "Child 2", state: :todo)

    @source_item.descendant.add_active_item(child1.id)
    @source_item.descendant.add_active_item(child2.id)
    @source_item.descendant.save!

    # Add grandchildren to child1 (reload to get auto-created descendant)
    child1.reload
    child1.descendant || child1.create_descendant!
    grandchild1 = @user.items.create!(title: "Grandchild 1", state: :todo)
    grandchild2 = @user.items.create!(title: "Grandchild 2", state: :done)

    child1.descendant.add_active_item(grandchild1.id)
    child1.descendant.add_inactive_item(grandchild2.id)
    child1.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Check first level
    new_child_ids = new_item.descendant.extract_active_item_ids
    assert_equal 2, new_child_ids.length
    new_child1 = Item.find_by(id: new_child_ids.first, title: "Child 1")
    assert_not_nil new_child1
    assert_equal child1.id, new_child1.source_item_id

    # Check second level - only active items should be copied
    assert_not_nil new_child1.descendant
    new_grandchild_active_ids = new_child1.descendant.extract_active_item_ids
    new_grandchild_inactive_ids = new_child1.descendant.extract_inactive_item_ids

    assert_equal 1, new_grandchild_active_ids.length
    assert_equal 0, new_grandchild_inactive_ids.length

    new_grandchild1 = Item.find(new_grandchild_active_ids.first)

    assert_equal "Grandchild 1", new_grandchild1.title
    assert_equal grandchild1.id, new_grandchild1.source_item_id
  end

  test "sections_with_no_active_items: false copies only active items" do
    @source_item.create_descendant! unless @source_item.descendant

    section = @user.items.create!(title: "Section", item_type: :section, state: :todo)
    active_item = @user.items.create!(title: "Active Item", state: :todo)
    inactive_item = @user.items.create!(title: "Inactive Item", state: :done)

    @source_item.descendant.add_active_item(section.id)
    @source_item.descendant.add_active_item(active_item.id)
    @source_item.descendant.add_inactive_item(inactive_item.id)
    @source_item.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Only active items should be copied (section and active item), inactive items NEVER migrate
    new_active_ids = new_item.descendant.extract_active_item_ids
    new_inactive_ids = new_item.descendant.extract_inactive_item_ids

    assert_equal 2, new_active_ids.length
    assert_equal 0, new_inactive_ids.length

    all_items = Item.where(id: new_active_ids)
    assert_equal [ "Active Item", "Section" ], all_items.pluck(:title).sort
  end

  test "sections_with_no_active_items: true skips inactive items but keeps sections" do
    @source_item.create_descendant! unless @source_item.descendant

    section = @user.items.create!(title: "Section", item_type: :section, state: :todo)
    active_item = @user.items.create!(title: "Active Item", state: :todo)
    inactive_item = @user.items.create!(title: "Inactive Item", state: :done)

    @source_item.descendant.add_active_item(section.id)
    @source_item.descendant.add_active_item(active_item.id)
    @source_item.descendant.add_inactive_item(inactive_item.id)
    @source_item.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => true, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Sections and active items should be copied, but not inactive non-section items
    new_active_ids = new_item.descendant.extract_active_item_ids
    new_inactive_ids = new_item.descendant.extract_inactive_item_ids

    assert_equal 2, new_active_ids.length
    assert_equal 0, new_inactive_ids.length

    active_items = Item.where(id: new_active_ids)
    assert_equal [ "Active Item", "Section" ], active_items.pluck(:title).sort
  end

  test "sections_with_no_active_items: true copies empty sections" do
    @source_item.create_descendant! unless @source_item.descendant

    # Create a section that only has inactive items
    section = @user.items.create!(title: "Empty Section", item_type: :section, state: :todo)
    @source_item.descendant.add_active_item(section.id)
    @source_item.descendant.save!

    section.reload
    section.descendant || section.create_descendant!
    inactive_child = @user.items.create!(title: "Done task", state: :done)
    section.descendant.add_inactive_item(inactive_child.id)
    section.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => true, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Section should be copied even though it only had inactive items
    new_section_id = new_item.descendant.extract_active_item_ids.first
    new_section = Item.find(new_section_id)

    assert_equal "Empty Section", new_section.title
    assert_equal "section", new_section.item_type

    # Section should be copied but have no children (inactive items were skipped)
    if new_section.descendant
      new_section_active_ids = new_section.descendant.extract_active_item_ids
      new_section_inactive_ids = new_section.descendant.extract_inactive_item_ids

      assert_equal 0, new_section_active_ids.length
      assert_equal 0, new_section_inactive_ids.length
    end
  end

  test "uses user default copy_settings when not provided" do
    # Set user's default settings
    @user.day_migration_settings = {
      "items" => { "sections_with_no_active_items" => true, "notes" => true }
    }
    @user.save!

    @source_item.create_descendant! unless @source_item.descendant
    active_item = @user.items.create!(title: "Active Item", state: :todo)
    inactive_item = @user.items.create!(title: "Inactive Item", state: :done)
    @source_item.descendant.add_active_item(active_item.id)
    @source_item.descendant.add_inactive_item(inactive_item.id)
    @source_item.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user
      # No copy_settings provided, should use user defaults
    )

    result = service.call
    new_item = result[:new_item]

    # Only active item should be copied due to user settings (sections_with_no_active_items: true)
    new_active_ids = new_item.descendant.extract_active_item_ids
    new_inactive_ids = new_item.descendant.extract_inactive_item_ids

    assert_equal 1, new_active_ids.length
    assert_equal 0, new_inactive_ids.length

    copied_item = Item.find(new_active_ids.first)
    assert_equal "Active Item", copied_item.title
  end

  test "copies nested tree with mixed states" do
    @source_item.create_descendant! unless @source_item.descendant

    todo_child = @user.items.create!(title: "Todo Child", state: :todo)
    done_child = @user.items.create!(title: "Done Child", state: :done)
    deferred_child = @user.items.create!(title: "Deferred Child", state: :deferred)

    @source_item.descendant.add_active_item(todo_child.id)
    @source_item.descendant.add_inactive_item(done_child.id)
    @source_item.descendant.add_inactive_item(deferred_child.id)
    @source_item.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    new_active_ids = new_item.descendant.extract_active_item_ids
    new_inactive_ids = new_item.descendant.extract_inactive_item_ids

    # Only active items should be migrated - inactive items NEVER migrate
    assert_equal 1, new_active_ids.length
    assert_equal 0, new_inactive_ids.length

    new_todo = Item.find(new_active_ids.first)
    assert_equal "Todo Child", new_todo.title
    assert_equal "todo", new_todo.state
  end

  test "copies section with all items when sections_with_no_active_items is false" do
    @source_item.create_descendant! unless @source_item.descendant

    section = @user.items.create!(title: "Work Section", item_type: :section, state: :todo)
    @source_item.descendant.add_active_item(section.id)
    @source_item.descendant.save!

    # Add items under section (reload to get auto-created descendant)
    section.reload
    section.descendant || section.create_descendant!
    active_child = @user.items.create!(title: "Active task", state: :todo)
    inactive_child = @user.items.create!(title: "Done task", state: :done)
    section.descendant.add_active_item(active_child.id)
    section.descendant.add_inactive_item(inactive_child.id)
    section.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Section should be copied
    new_section_id = new_item.descendant.extract_active_item_ids.first
    new_section = Item.find(new_section_id)

    assert_equal "Work Section", new_section.title
    assert_equal "section", new_section.item_type
    assert_equal section.id, new_section.source_item_id

    # Section's children - only active items should be copied (inactive items NEVER migrate)
    assert_not_nil new_section.descendant
    new_active_child_ids = new_section.descendant.extract_active_item_ids
    new_inactive_child_ids = new_section.descendant.extract_inactive_item_ids

    assert_equal 1, new_active_child_ids.length
    assert_equal 0, new_inactive_child_ids.length

    new_active_child = Item.find(new_active_child_ids.first)

    assert_equal "Active task", new_active_child.title
  end

  test "copies section without inactive items when sections_with_no_active_items is true" do
    @source_item.create_descendant! unless @source_item.descendant

    section = @user.items.create!(title: "Work Section", item_type: :section, state: :todo)
    @source_item.descendant.add_active_item(section.id)
    @source_item.descendant.save!

    # Add items under section (reload to get auto-created descendant)
    section.reload
    section.descendant || section.create_descendant!
    active_child = @user.items.create!(title: "Active task", state: :todo)
    inactive_child = @user.items.create!(title: "Done task", state: :done)
    section.descendant.add_active_item(active_child.id)
    section.descendant.add_inactive_item(inactive_child.id)
    section.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => true, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Section should be copied
    new_section_id = new_item.descendant.extract_active_item_ids.first
    new_section = Item.find(new_section_id)

    assert_equal "Work Section", new_section.title
    assert_equal "section", new_section.item_type

    # Only active child should be copied, no inactive items
    assert_not_nil new_section.descendant
    new_active_child_ids = new_section.descendant.extract_active_item_ids
    new_inactive_child_ids = new_section.descendant.extract_inactive_item_ids

    assert_equal 1, new_active_child_ids.length
    assert_equal 0, new_inactive_child_ids.length

    new_active_child = Item.find(new_active_child_ids.first)
    assert_equal "Active task", new_active_child.title
  end

  test "migrates section with nested sections containing active items" do
    @source_item.create_descendant! unless @source_item.descendant

    # Create: parent section -> child section -> active item
    parent_section = @user.items.create!(title: "Parent Section", item_type: :section, state: :todo)
    @source_item.descendant.add_active_item(parent_section.id)
    @source_item.descendant.save!

    parent_section.reload
    parent_section.descendant || parent_section.create_descendant!
    child_section = @user.items.create!(title: "Child Section", item_type: :section, state: :todo)
    parent_section.descendant.add_active_item(child_section.id)
    parent_section.descendant.save!

    child_section.reload
    child_section.descendant || child_section.create_descendant!
    active_item = @user.items.create!(title: "Active Task", state: :todo)
    child_section.descendant.add_active_item(active_item.id)
    child_section.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Parent section should be copied
    new_parent_section_id = new_item.descendant.extract_active_item_ids.first
    new_parent_section = Item.find(new_parent_section_id)
    assert_equal "Parent Section", new_parent_section.title

    # Child section should be copied
    new_child_section_id = new_parent_section.descendant.extract_active_item_ids.first
    new_child_section = Item.find(new_child_section_id)
    assert_equal "Child Section", new_child_section.title

    # Active item should be copied
    new_active_item_id = new_child_section.descendant.extract_active_item_ids.first
    new_active_item = Item.find(new_active_item_id)
    assert_equal "Active Task", new_active_item.title
  end

  test "does not migrate section with nested sections but no active items when setting is false" do
    @source_item.create_descendant! unless @source_item.descendant

    # Create: parent section -> child section -> inactive item
    parent_section = @user.items.create!(title: "Parent Section", item_type: :section, state: :todo)
    @source_item.descendant.add_active_item(parent_section.id)
    @source_item.descendant.save!

    parent_section.reload
    parent_section.descendant || parent_section.create_descendant!
    child_section = @user.items.create!(title: "Child Section", item_type: :section, state: :todo)
    parent_section.descendant.add_active_item(child_section.id)
    parent_section.descendant.save!

    child_section.reload
    child_section.descendant || child_section.create_descendant!
    inactive_item = @user.items.create!(title: "Done Task", state: :done)
    child_section.descendant.add_inactive_item(inactive_item.id)
    child_section.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Parent section should NOT be copied (no active items in tree)
    new_active_ids = new_item.descendant.extract_active_item_ids if new_item.descendant
    assert_equal 0, (new_active_ids || []).length
  end

  test "migrates section with nested sections but no active items as empty when setting is true" do
    @source_item.create_descendant! unless @source_item.descendant

    # Create: parent section -> child section -> inactive item
    parent_section = @user.items.create!(title: "Parent Section", item_type: :section, state: :todo)
    @source_item.descendant.add_active_item(parent_section.id)
    @source_item.descendant.save!

    parent_section.reload
    parent_section.descendant || parent_section.create_descendant!
    child_section = @user.items.create!(title: "Child Section", item_type: :section, state: :todo)
    parent_section.descendant.add_active_item(child_section.id)
    parent_section.descendant.save!

    child_section.reload
    child_section.descendant || child_section.create_descendant!
    inactive_item = @user.items.create!(title: "Done Task", state: :done)
    child_section.descendant.add_inactive_item(inactive_item.id)
    child_section.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => true, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Parent section should be copied with empty descendant
    new_parent_section_id = new_item.descendant.extract_active_item_ids.first
    new_parent_section = Item.find(new_parent_section_id)
    assert_equal "Parent Section", new_parent_section.title
    assert_not_nil new_parent_section.descendant

    # Parent section should have empty descendant (child section also has no active items)
    parent_active_ids = new_parent_section.descendant.extract_active_item_ids
    assert_equal 0, parent_active_ids.length
  end

  test "migrates multi-level nested sections with active items at deepest level" do
    @source_item.create_descendant! unless @source_item.descendant

    # Create: level1 -> level2 -> level3 -> active item
    level1 = @user.items.create!(title: "Level 1", item_type: :section, state: :todo)
    @source_item.descendant.add_active_item(level1.id)
    @source_item.descendant.save!

    level1.reload
    level1.descendant || level1.create_descendant!
    level2 = @user.items.create!(title: "Level 2", item_type: :section, state: :todo)
    level1.descendant.add_active_item(level2.id)
    level1.descendant.save!

    level2.reload
    level2.descendant || level2.create_descendant!
    level3 = @user.items.create!(title: "Level 3", item_type: :section, state: :todo)
    level2.descendant.add_active_item(level3.id)
    level2.descendant.save!

    level3.reload
    level3.descendant || level3.create_descendant!
    deep_item = @user.items.create!(title: "Deep Task", state: :todo)
    level3.descendant.add_active_item(deep_item.id)
    level3.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Traverse the tree to verify all levels were copied
    new_level1_id = new_item.descendant.extract_active_item_ids.first
    new_level1 = Item.find(new_level1_id)
    assert_equal "Level 1", new_level1.title

    new_level2_id = new_level1.descendant.extract_active_item_ids.first
    new_level2 = Item.find(new_level2_id)
    assert_equal "Level 2", new_level2.title

    new_level3_id = new_level2.descendant.extract_active_item_ids.first
    new_level3 = Item.find(new_level3_id)
    assert_equal "Level 3", new_level3.title

    new_deep_item_id = new_level3.descendant.extract_active_item_ids.first
    new_deep_item = Item.find(new_deep_item_id)
    assert_equal "Deep Task", new_deep_item.title
  end

  test "CRITICAL: does not migrate completable items in done state" do
    @source_item.create_descendant! unless @source_item.descendant

    todo_item = @user.items.create!(title: "Todo Item", item_type: :completable, state: :todo)
    done_item = @user.items.create!(title: "Done Item", item_type: :completable, state: :done)

    @source_item.descendant.add_active_item(todo_item.id)
    @source_item.descendant.add_active_item(done_item.id)
    @source_item.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # ONLY the todo item should be copied, NEVER the done item
    new_active_ids = new_item.descendant.extract_active_item_ids
    assert_equal 1, new_active_ids.length

    copied_item = Item.find(new_active_ids.first)
    assert_equal "Todo Item", copied_item.title
    assert_equal "todo", copied_item.state
  end

  test "CRITICAL: does not migrate completable items in dropped state" do
    @source_item.create_descendant! unless @source_item.descendant

    todo_item = @user.items.create!(title: "Todo Item", item_type: :completable, state: :todo)
    dropped_item = @user.items.create!(title: "Dropped Item", item_type: :completable, state: :dropped)

    @source_item.descendant.add_active_item(todo_item.id)
    @source_item.descendant.add_active_item(dropped_item.id)
    @source_item.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # ONLY the todo item should be copied, NEVER the dropped item
    new_active_ids = new_item.descendant.extract_active_item_ids
    assert_equal 1, new_active_ids.length

    copied_item = Item.find(new_active_ids.first)
    assert_equal "Todo Item", copied_item.title
  end

  test "CRITICAL: does not migrate completable items in deferred state" do
    @source_item.create_descendant! unless @source_item.descendant

    todo_item = @user.items.create!(title: "Todo Item", item_type: :completable, state: :todo)
    deferred_item = @user.items.create!(title: "Deferred Item", item_type: :completable, state: :deferred, deferred_to: 1.day.from_now)

    @source_item.descendant.add_active_item(todo_item.id)
    @source_item.descendant.add_active_item(deferred_item.id)
    @source_item.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # ONLY the todo item should be copied, NEVER the deferred item
    new_active_ids = new_item.descendant.extract_active_item_ids
    assert_equal 1, new_active_ids.length

    copied_item = Item.find(new_active_ids.first)
    assert_equal "Todo Item", copied_item.title
  end

  test "CRITICAL: does not migrate section when it only contains non-todo completable items" do
    @source_item.create_descendant! unless @source_item.descendant

    section = @user.items.create!(title: "Work Section", item_type: :section, state: :todo)
    @source_item.descendant.add_active_item(section.id)
    @source_item.descendant.save!

    section.reload
    section.descendant || section.create_descendant!
    done_item = @user.items.create!(title: "Done Task", item_type: :completable, state: :done)
    deferred_item = @user.items.create!(title: "Deferred Task", item_type: :completable, state: :deferred)
    section.descendant.add_active_item(done_item.id)
    section.descendant.add_active_item(deferred_item.id)
    section.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Section should NOT be copied because it has no todo items
    new_active_ids = new_item.descendant.extract_active_item_ids if new_item.descendant
    assert_equal 0, (new_active_ids || []).length
  end

  test "CRITICAL: migrates section as empty when it only contains non-todo items and setting is true" do
    @source_item.create_descendant! unless @source_item.descendant

    section = @user.items.create!(title: "Work Section", item_type: :section, state: :todo)
    @source_item.descendant.add_active_item(section.id)
    @source_item.descendant.save!

    section.reload
    section.descendant || section.create_descendant!
    done_item = @user.items.create!(title: "Done Task", item_type: :completable, state: :done)
    section.descendant.add_active_item(done_item.id)
    section.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => true, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Section should be copied with empty descendant
    new_section_id = new_item.descendant.extract_active_item_ids.first
    new_section = Item.find(new_section_id)
    assert_equal "Work Section", new_section.title
    assert_not_nil new_section.descendant

    # Section should have empty descendant (done item was not copied)
    section_active_ids = new_section.descendant.extract_active_item_ids
    assert_equal 0, section_active_ids.length
  end

  test "CRITICAL: does not migrate nested section when only deep items are non-todo" do
    @source_item.create_descendant! unless @source_item.descendant

    parent_section = @user.items.create!(title: "Parent Section", item_type: :section, state: :todo)
    @source_item.descendant.add_active_item(parent_section.id)
    @source_item.descendant.save!

    parent_section.reload
    parent_section.descendant || parent_section.create_descendant!
    child_section = @user.items.create!(title: "Child Section", item_type: :section, state: :todo)
    parent_section.descendant.add_active_item(child_section.id)
    parent_section.descendant.save!

    child_section.reload
    child_section.descendant || child_section.create_descendant!
    done_item = @user.items.create!(title: "Done Task", item_type: :completable, state: :done)
    child_section.descendant.add_active_item(done_item.id)
    child_section.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Parent section should NOT be copied (no todo items in entire tree)
    new_active_ids = new_item.descendant.extract_active_item_ids if new_item.descendant
    assert_equal 0, (new_active_ids || []).length
  end

  test "CRITICAL: migrates nested sections with mix of todo and non-todo items correctly" do
    @source_item.create_descendant! unless @source_item.descendant

    section = @user.items.create!(title: "Work Section", item_type: :section, state: :todo)
    @source_item.descendant.add_active_item(section.id)
    @source_item.descendant.save!

    section.reload
    section.descendant || section.create_descendant!
    todo_item = @user.items.create!(title: "Todo Task", item_type: :completable, state: :todo)
    done_item = @user.items.create!(title: "Done Task", item_type: :completable, state: :done)
    deferred_item = @user.items.create!(title: "Deferred Task", item_type: :completable, state: :deferred)
    dropped_item = @user.items.create!(title: "Dropped Task", item_type: :completable, state: :dropped)

    section.descendant.add_active_item(todo_item.id)
    section.descendant.add_active_item(done_item.id)
    section.descendant.add_active_item(deferred_item.id)
    section.descendant.add_active_item(dropped_item.id)
    section.descendant.save!

    service = Items::CopyToDescendantService.new(
      source_item: @source_item,
      target_descendant: @target_descendant,
      user: @user,
      copy_settings: { "sections_with_no_active_items" => false, "notes" => true }
    )

    result = service.call
    new_item = result[:new_item]

    assert result[:success]

    # Section should be copied
    new_section_id = new_item.descendant.extract_active_item_ids.first
    new_section = Item.find(new_section_id)
    assert_equal "Work Section", new_section.title

    # ONLY todo item should be copied, NEVER done/deferred/dropped
    section_active_ids = new_section.descendant.extract_active_item_ids
    assert_equal 1, section_active_ids.length

    copied_item = Item.find(section_active_ids.first)
    assert_equal "Todo Task", copied_item.title
    assert_equal "todo", copied_item.state
  end
end
