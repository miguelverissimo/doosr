# frozen_string_literal: true

require "test_helper"

class Items::DeferServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @today = Date.today
    @tomorrow = @today + 1.day
    @source_day = @user.days.create!(date: @today, state: :open)
    @source_descendant = @source_day.descendant

    @item = @user.items.create!(
      title: "Test Item",
      item_type: :completable,
      state: :todo
    )
    @source_descendant.add_active_item(@item.id)
    @source_descendant.save!
  end

  test "defers todo item to target date" do
    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]
    assert_not_nil result[:new_item]

    # Check source item state
    @item.reload
    assert_equal "deferred", @item.state
    assert_not_nil @item.deferred_at
    assert_equal @tomorrow.to_time.to_i, @item.deferred_to.to_i

    # Check source moved to inactive
    @source_descendant.reload
    assert @source_descendant.inactive_item?(@item.id)
    assert_not @source_descendant.active_item?(@item.id)

    # Check new item created on target date
    new_item = result[:new_item]
    assert_equal "todo", new_item.state
    assert_equal @item.title, new_item.title
    assert_equal @item.id, new_item.source_item_id
  end

  test "creates target day if it does not exist" do
    target_date = @today + 5.days

    service = Items::DeferService.new(
      source_item: @item,
      target_date: target_date,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check target day was created
    target_day = @user.days.find_by(date: target_date)
    assert_not_nil target_day
    assert_not_nil target_day.descendant

    # Check new item is in target day
    new_item = result[:new_item]
    assert target_day.descendant.active_item?(new_item.id)
  end

  test "creates permanent sections on new target day" do
    @user.permanent_sections = ["Work", "Personal"]
    @user.save!

    target_date = @today + 3.days

    service = Items::DeferService.new(
      source_item: @item,
      target_date: target_date,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check permanent sections were created
    target_day = @user.days.find_by(date: target_date)
    active_item_ids = target_day.descendant.extract_active_item_ids
    sections = Item.sections.where(id: active_item_ids)

    assert_equal 2, sections.count
    assert_includes sections.pluck(:title), "Work"
    assert_includes sections.pluck(:title), "Personal"
  end

  test "uses existing target day if it exists" do
    # Create target day first
    target_day = @user.days.create!(date: @tomorrow, state: :open)
    existing_item = @user.items.create!(title: "Existing", state: :todo)
    target_day.descendant.add_active_item(existing_item.id)
    target_day.descendant.save!

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check target day still has existing item
    target_day.reload
    assert target_day.descendant.active_item?(existing_item.id)

    # Check new item was added
    new_item = result[:new_item]
    assert target_day.descendant.active_item?(new_item.id)
  end

  test "returns validation error for non-todo item" do
    @item.update!(state: :done)

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert_not result[:success]
    assert_includes result[:error], "Only items in 'todo' state can be deferred"
  end

  test "returns validation error for dropped item" do
    @item.update!(state: :dropped)

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert_not result[:success]
    assert_includes result[:error], "Only items in 'todo' state can be deferred"
  end

  test "returns validation error for already deferred item" do
    @item.update!(state: :deferred, deferred_to: @tomorrow)

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow + 1.day,
      user: @user
    )

    result = service.call

    assert_not result[:success]
    assert_includes result[:error], "Only items in 'todo' state can be deferred"
  end

  test "counts nested todo items" do
    # Create nested structure
    @item.create_descendant! unless @item.descendant
    child1 = @user.items.create!(title: "Child 1", state: :todo)
    child2 = @user.items.create!(title: "Child 2", state: :todo)

    @item.descendant.add_active_item(child1.id)
    @item.descendant.add_active_item(child2.id)
    @item.descendant.save!

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]
    assert_equal 2, result[:nested_items_count]
  end

  test "counts nested todo items recursively" do
    # Create multi-level nested structure
    @item.create_descendant! unless @item.descendant
    child1 = @user.items.create!(title: "Child 1", state: :todo)
    @item.descendant.add_active_item(child1.id)
    @item.descendant.save!

    child1.reload
    child1.create_descendant! unless child1.descendant
    grandchild1 = @user.items.create!(title: "Grandchild 1", state: :todo)
    grandchild2 = @user.items.create!(title: "Grandchild 2", state: :todo)
    child1.descendant.add_active_item(grandchild1.id)
    child1.descendant.add_active_item(grandchild2.id)
    child1.descendant.save!

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]
    assert_equal 3, result[:nested_items_count]
  end

  test "defers item with nested children recursively" do
    @item.create_descendant! unless @item.descendant
    child1 = @user.items.create!(title: "Child 1", state: :todo)
    child2 = @user.items.create!(title: "Child 2", state: :todo)

    @item.descendant.add_active_item(child1.id)
    @item.descendant.add_active_item(child2.id)
    @item.descendant.save!

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check new item has descendants
    new_item = result[:new_item]
    assert_not_nil new_item.descendant

    new_child_ids = new_item.descendant.extract_active_item_ids
    assert_equal 2, new_child_ids.length

    # Check children were copied
    new_children = Item.where(id: new_child_ids)
    assert_equal ["Child 1", "Child 2"], new_children.pluck(:title).sort
  end

  test "uses user day_migration_settings for copying" do
    @user.day_migration_settings = {
      "items" => { "sections_with_no_active_items" => false, "notes" => true }
    }
    @user.save!

    @item.create_descendant! unless @item.descendant
    section = @user.items.create!(title: "Section", item_type: :section, state: :todo)
    @item.descendant.add_active_item(section.id)
    @item.descendant.save!

    # Section has a done item (not in todo state) - should not be copied with setting = false
    section.reload
    section.create_descendant! unless section.descendant
    done_task = @user.items.create!(title: "Done Task", state: :done)
    section.descendant.add_active_item(done_task.id) # Add to active_items even though it's done
    section.descendant.save!

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check section was not copied (has no todo items in its tree)
    new_item = result[:new_item]
    if new_item.descendant
      new_active_ids = new_item.descendant.extract_active_item_ids
      assert_equal 0, new_active_ids.length
    end
  end

  test "copies recurrence_rule to deferred item" do
    @item.update!(recurrence_rule: "FREQ=DAILY")

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]

    new_item = result[:new_item]
    assert_equal "FREQ=DAILY", new_item.recurrence_rule
  end

  test "wraps everything in transaction" do
    # Force an error during copy by making user invalid
    invalid_user = User.new

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: invalid_user
    )

    result = service.call

    assert_not result[:success]
    assert_not_nil result[:error]

    # Check source item was not modified (transaction rollback)
    @item.reload
    assert_equal "todo", @item.state
    assert_nil @item.deferred_at
    assert_nil @item.deferred_to
  end

  test "parses string target_date" do
    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow.to_s,
      user: @user
    )

    result = service.call

    assert result[:success]

    @item.reload
    assert_equal @tomorrow.to_time.to_i, @item.deferred_to.to_i
  end

  test "defers section with nested items" do
    section = @user.items.create!(title: "Work Section", item_type: :section, state: :todo)
    @source_descendant.add_active_item(section.id)
    @source_descendant.save!

    section.reload
    section.create_descendant! unless section.descendant
    task = @user.items.create!(title: "Task", state: :todo)
    section.descendant.add_active_item(task.id)
    section.descendant.save!

    service = Items::DeferService.new(
      source_item: section,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check section was deferred (sections stay in todo state but are marked with defer timestamps)
    section.reload
    assert_equal "todo", section.state
    assert_not_nil section.deferred_at
    assert_not_nil section.deferred_to

    # Check new section has nested task
    new_section = result[:new_item]
    assert_not_nil new_section.descendant

    new_task_ids = new_section.descendant.extract_active_item_ids
    assert_equal 1, new_task_ids.length

    new_task = Item.find(new_task_ids.first)
    assert_equal "Task", new_task.title
  end

  test "returns nested_items_count zero for item without children" do
    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]
    assert_equal 0, result[:nested_items_count]
  end

  test "defers item from nested position" do
    # Create parent item with child
    parent = @user.items.create!(title: "Parent", state: :todo)
    @source_descendant.add_active_item(parent.id)
    @source_descendant.save!

    parent.reload
    parent.create_descendant! unless parent.descendant
    child = @user.items.create!(title: "Child", state: :todo)
    parent.descendant.add_active_item(child.id)
    parent.descendant.save!

    # Defer the child item
    service = Items::DeferService.new(
      source_item: child,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check child was deferred
    child.reload
    assert_equal "deferred", child.state

    # Check child moved to inactive in parent
    parent.reload
    assert parent.descendant.inactive_item?(child.id)
    assert_not parent.descendant.active_item?(child.id)

    # Check new child created on target date (at root level)
    new_child = result[:new_item]
    target_day = @user.days.find_by(date: @tomorrow)
    assert target_day.descendant.active_item?(new_child.id)
  end

  test "copies extra_data to deferred item" do
    @item.update!(extra_data: { "priority" => "high", "tags" => ["urgent"] })

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]

    new_item = result[:new_item]
    assert_equal @item.extra_data, new_item.extra_data
  end

  test "only counts todo items in nested tree for nested_items_count" do
    @item.create_descendant! unless @item.descendant
    todo_child = @user.items.create!(title: "Todo", state: :todo)
    done_child = @user.items.create!(title: "Done", state: :done)

    @item.descendant.add_active_item(todo_child.id)
    @item.descendant.add_inactive_item(done_child.id)
    @item.descendant.save!

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]
    # Should only count the todo child, not the done child
    assert_equal 1, result[:nested_items_count]
  end

  test "CRITICAL: creates permanent sections on NEW target day" do
    @user.permanent_sections = ["Work", "Personal", "Errands"]
    @user.save!

    target_date = @today + 5.days

    service = Items::DeferService.new(
      source_item: @item,
      target_date: target_date,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check target day was created with ALL permanent sections
    target_day = @user.days.find_by(date: target_date)
    assert_not_nil target_day
    assert_not_nil target_day.descendant

    active_item_ids = target_day.descendant.extract_active_item_ids
    sections = Item.sections.where(id: active_item_ids)

    assert_equal 3, sections.count
    assert_includes sections.pluck(:title), "Work"
    assert_includes sections.pluck(:title), "Personal"
    assert_includes sections.pluck(:title), "Errands"

    # Verify they are all marked as permanent sections
    sections.each do |section|
      assert section.extra_data&.dig("permanent_section"), "Section #{section.title} should be marked as permanent"
    end
  end

  test "CRITICAL: creates permanent sections on EXISTING target day that doesn't have them" do
    @user.permanent_sections = ["Work", "Personal"]
    @user.save!

    # Create target day WITHOUT permanent sections
    target_day = @user.days.create!(date: @tomorrow, state: :open)

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check target day now has ALL permanent sections
    target_day.reload
    active_item_ids = target_day.descendant.extract_active_item_ids
    sections = Item.sections.where(id: active_item_ids)

    assert_equal 2, sections.count
    assert_includes sections.pluck(:title), "Work"
    assert_includes sections.pluck(:title), "Personal"
  end

  test "CRITICAL: item NOT in permanent section goes to day root on target day" do
    @user.permanent_sections = ["Work", "Personal"]
    @user.save!

    # Item is at day root (not in any section)
    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check new item is at day root (not in a section)
    target_day = @user.days.find_by(date: @tomorrow)
    new_item = result[:new_item]

    # Should be in day's descendant active_items
    assert target_day.descendant.active_item?(new_item.id)

    # Should NOT be in any section's descendant
    sections = Item.sections.where(id: target_day.descendant.extract_active_item_ids)
    sections.each do |section|
      if section.descendant
        assert_not section.descendant.active_item?(new_item.id), "Item should not be in #{section.title} section"
      end
    end
  end

  test "CRITICAL: item IN permanent section goes to SAME section on target day" do
    @user.permanent_sections = ["Work", "Personal"]
    @user.save!

    # Create a permanent section on source day
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { permanent_section: true }
    )
    @source_descendant.add_active_item(work_section.id)
    @source_descendant.save!

    # Ensure work section has a descendant
    work_section.reload
    work_section.descendant || work_section.create_descendant!(active_items: [], inactive_items: [])

    # Add item to work section
    work_section.descendant.remove_active_item(@item.id) rescue nil # Remove from day root if present
    work_section.descendant.add_active_item(@item.id)
    work_section.descendant.save!

    # Also remove from day root
    @source_descendant.remove_active_item(@item.id)
    @source_descendant.save!

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]

    # Check new item is in Work section on target day
    target_day = @user.days.find_by(date: @tomorrow)
    new_item = result[:new_item]

    # Find Work section on target day
    target_work_section = Item.sections.where(id: target_day.descendant.extract_active_item_ids).find_by(title: "Work")
    assert_not_nil target_work_section, "Work section should exist on target day"

    # Should be in Work section's descendant
    assert target_work_section.descendant.active_item?(new_item.id), "Item should be in Work section on target day"

    # Should NOT be in day's root
    assert_not target_day.descendant.active_item?(new_item.id), "Item should NOT be at day root"
  end

  test "CRITICAL: item in nested position within permanent section stays within that section" do
    @user.permanent_sections = ["Work"]
    @user.save!

    # Create Work section on source day
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { permanent_section: true }
    )
    @source_descendant.add_active_item(work_section.id)
    @source_descendant.save!

    work_section.reload
    work_section.descendant || work_section.create_descendant!(active_items: [], inactive_items: [])

    # Create a parent item in Work section
    parent = @user.items.create!(title: "Project A", state: :todo)
    work_section.descendant.add_active_item(parent.id)
    work_section.descendant.save!

    parent.reload
    parent.create_descendant!(active_items: [], inactive_items: [])

    # Add our test item as a child of parent (nested within Work section)
    parent.descendant.add_active_item(@item.id)
    parent.descendant.save!

    # Remove from source day root
    @source_descendant.remove_active_item(@item.id)
    @source_descendant.save!

    service = Items::DeferService.new(
      source_item: @item,
      target_date: @tomorrow,
      user: @user
    )

    result = service.call

    assert result[:success]

    # The new item should be in Work section on target day
    target_day = @user.days.find_by(date: @tomorrow)
    new_item = result[:new_item]

    target_work_section = Item.sections.where(id: target_day.descendant.extract_active_item_ids).find_by(title: "Work")
    assert_not_nil target_work_section

    # Should be directly in Work section's descendant (not nested under Project A)
    assert target_work_section.descendant.active_item?(new_item.id), "Item should be in Work section"
  end
end
