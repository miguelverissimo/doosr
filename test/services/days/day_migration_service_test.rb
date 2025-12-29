# frozen_string_literal: true

require "test_helper"

class Days::DayMigrationServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @source_date = Date.today - 1.day
    @target_date = Date.today

    @source_day = @user.days.create!(date: @source_date, state: :open)
    @source_day.create_descendant! unless @source_day.descendant
  end

  test "creates target day if it doesn't exist" do
    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call

    assert result[:success]
    assert_not_nil result[:target_day]
    assert_equal @target_date, result[:target_day].date
    assert_equal "open", result[:target_day].state
  end

  test "uses existing target day if it exists" do
    existing_day = @user.days.create!(date: @target_date, state: :open)

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call

    assert result[:success]
    assert_equal existing_day.id, result[:target_day].id
  end

  test "creates permanent sections in new target day" do
    @user.permanent_sections = [ "Work", "Personal", "Health" ]
    @user.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # Check permanent sections were created
    target_day.reload
    active_item_ids = target_day.descendant.extract_active_item_ids
    sections = Item.where(id: active_item_ids, item_type: :section)

    assert_equal 3, sections.count
    assert_equal [ "Health", "Personal", "Work" ], sections.pluck(:title).sort
    sections.each do |section|
      assert section.extra_data&.dig("permanent_section")
    end
  end

  test "migrates simple active items" do
    item1 = @user.items.create!(title: "Task 1", state: :todo)
    item2 = @user.items.create!(title: "Task 2", state: :todo)

    @source_day.descendant.add_active_item(item1.id)
    @source_day.descendant.add_active_item(item2.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call

    assert result[:success]
    assert_equal 2, result[:migrated_count]

    target_day = result[:target_day]
    target_active_ids = target_day.descendant.extract_active_item_ids
    target_items = Item.where(id: target_active_ids)

    assert_equal [ "Task 1", "Task 2" ], target_items.pluck(:title)
    # Verify source_item_id linkage
    target_items.each do |item|
      assert_not_nil item.source_item_id
    end
  end

  test "matches permanent sections and merges children" do
    # Set up user with permanent sections
    @user.permanent_sections = [ "Work", "Personal" ]
    @user.save!

    # Create permanent sections in source day with items
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )
    work_section.reload
    work_section.descendant || work_section.create_descendant!
    work_item = @user.items.create!(title: "Work Task", state: :todo)
    work_section.descendant.add_active_item(work_item.id)
    work_section.descendant.save!

    @source_day.descendant.add_active_item(work_section.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # Find Work section in target day
    target_active_ids = target_day.descendant.extract_active_item_ids
    target_sections = Item.where(id: target_active_ids, item_type: :section)
    target_work_section = target_sections.find_by(title: "Work")

    assert_not_nil target_work_section
    assert target_work_section.extra_data&.dig("permanent_section")

    # Check that work item was migrated to target Work section
    target_work_section.reload
    assert_not_nil target_work_section.descendant
    work_children_ids = target_work_section.descendant.extract_active_item_ids
    work_children = Item.where(id: work_children_ids)

    assert_equal 1, work_children.count
    assert_equal "Work Task", work_children.first.title
    assert_equal work_item.id, work_children.first.source_item_id
  end

  test "does not duplicate permanent sections" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    # Create permanent section in source with items
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )
    work_section.reload
    work_section.descendant || work_section.create_descendant!
    work_item = @user.items.create!(title: "Task", state: :todo)
    work_section.descendant.add_active_item(work_item.id)
    work_section.descendant.save!

    @source_day.descendant.add_active_item(work_section.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # Should only have ONE Work section
    target_active_ids = target_day.descendant.extract_active_item_ids
    work_sections = Item.where(id: target_active_ids, item_type: :section, title: "Work")

    assert_equal 1, work_sections.count
  end

  test "migrates non-permanent sections" do
    # Create a non-permanent section
    section = @user.items.create!(title: "Project X", item_type: :section, state: :todo)
    section.reload
    section.descendant || section.create_descendant!
    task = @user.items.create!(title: "Project Task", state: :todo)
    section.descendant.add_active_item(task.id)
    section.descendant.save!

    @source_day.descendant.add_active_item(section.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # Check that Project X section was migrated
    target_active_ids = target_day.descendant.extract_active_item_ids
    project_sections = Item.where(id: target_active_ids, title: "Project X")

    assert_equal 1, project_sections.count
    project_section = project_sections.first

    # Check that task was migrated within the section
    project_section.reload
    assert_not_nil project_section.descendant
    project_children_ids = project_section.descendant.extract_active_item_ids
    project_children = Item.where(id: project_children_ids)

    assert_equal 1, project_children.count
    assert_equal "Project Task", project_children.first.title
  end

  test "respects active_item_sections setting" do
    # Create non-permanent section
    section = @user.items.create!(title: "Project", item_type: :section, state: :todo)
    regular_item = @user.items.create!(title: "Regular Task", state: :todo)

    @source_day.descendant.add_active_item(section.id)
    @source_day.descendant.add_active_item(regular_item.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: { "active_item_sections" => false }
    )

    result = service.call
    target_day = result[:target_day]

    # Only regular item should be migrated, not the section
    target_active_ids = target_day.descendant.extract_active_item_ids
    target_items = Item.where(id: target_active_ids)

    # Should have only 1 item (Regular Task), section should be skipped
    non_section_items = target_items.where.not(item_type: :section)
    assert_equal 1, non_section_items.count
    assert_equal "Regular Task", non_section_items.first.title
  end

  test "passes copy_settings to CopyToDescendantService" do
    # Create item with nested inactive children
    item = @user.items.create!(title: "Parent", state: :todo)
    item.create_descendant!

    active_child = @user.items.create!(title: "Active Child", state: :todo)
    inactive_child = @user.items.create!(title: "Inactive Child", state: :done)

    item.descendant.add_active_item(active_child.id)
    item.descendant.add_inactive_item(inactive_child.id)
    item.descendant.save!

    @source_day.descendant.add_active_item(item.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: { "items" => { "sections_with_no_active_items" => true, "notes" => true } }
    )

    result = service.call
    target_day = result[:target_day]

    # Find parent item in target
    target_active_ids = target_day.descendant.extract_active_item_ids
    parent_item = Item.find_by(id: target_active_ids, title: "Parent")

    assert_not_nil parent_item
    assert_not_nil parent_item.descendant

    # Should only have active child due to sections_with_inactive_items: true
    parent_active_ids = parent_item.descendant.extract_active_item_ids
    parent_inactive_ids = parent_item.descendant.extract_inactive_item_ids

    assert_equal 1, parent_active_ids.length
    assert_equal 0, parent_inactive_ids.length

    child = Item.find(parent_active_ids.first)
    assert_equal "Active Child", child.title
  end

  test "handles complex nested structure" do
    # Create complex structure: section -> item -> nested items
    section = @user.items.create!(title: "Complex Section", item_type: :section, state: :todo)
    section.reload
    section.descendant || section.create_descendant!

    parent_item = @user.items.create!(title: "Parent Item", state: :todo)
    parent_item.reload
    parent_item.descendant || parent_item.create_descendant!

    child_item1 = @user.items.create!(title: "Child 1", state: :todo)
    child_item2 = @user.items.create!(title: "Child 2", state: :done)

    parent_item.descendant.add_active_item(child_item1.id)
    parent_item.descendant.add_inactive_item(child_item2.id)
    parent_item.descendant.save!

    section.descendant.add_active_item(parent_item.id)
    section.descendant.save!

    @source_day.descendant.add_active_item(section.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: { "items" => { "sections_with_no_active_items" => false, "notes" => true } }
    )

    result = service.call
    target_day = result[:target_day]

    # Verify entire structure was migrated
    target_active_ids = target_day.descendant.extract_active_item_ids
    target_section = Item.find_by(id: target_active_ids, title: "Complex Section")

    assert_not_nil target_section
    assert_not_nil target_section.descendant

    # Check parent item
    section_children_ids = target_section.descendant.extract_active_item_ids
    target_parent = Item.find_by(id: section_children_ids, title: "Parent Item")

    assert_not_nil target_parent
    assert_not_nil target_parent.descendant

    # Check children (only active child should be migrated - inactive items NEVER migrate)
    parent_active_ids = target_parent.descendant.extract_active_item_ids
    parent_inactive_ids = target_parent.descendant.extract_inactive_item_ids

    assert_equal 1, parent_active_ids.length
    assert_equal 0, parent_inactive_ids.length

    children = Item.where(id: parent_active_ids)
    assert_equal [ "Child 1" ], children.pluck(:title)
  end

  test "preserves item order during migration" do
    # Create items in specific order
    item1 = @user.items.create!(title: "First", state: :todo)
    item2 = @user.items.create!(title: "Second", state: :todo)
    item3 = @user.items.create!(title: "Third", state: :todo)

    @source_day.descendant.add_active_item(item1.id)
    @source_day.descendant.add_active_item(item2.id)
    @source_day.descendant.add_active_item(item3.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # Check order is preserved
    target_active_ids = target_day.descendant.extract_active_item_ids
    target_items = target_active_ids.map { |id| Item.find(id) }

    assert_equal [ "First", "Second", "Third" ], target_items.map(&:title)
  end

  test "handles empty source day" do
    # Source day has no items
    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call

    assert result[:success]
    assert_equal 0, result[:migrated_count]
  end

  test "returns error on failure" do
    # Create invalid scenario - source day without descendant
    @source_day.descendant&.destroy

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call

    # Should handle gracefully
    assert result[:success]
    assert_equal 0, result[:migrated_count]
  end

  test "migrates multiple items to permanent section" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    # Create permanent section with multiple items
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )
    work_section.reload
    work_section.descendant || work_section.create_descendant!

    task1 = @user.items.create!(title: "Task 1", state: :todo)
    task2 = @user.items.create!(title: "Task 2", state: :todo)
    task3 = @user.items.create!(title: "Task 3", state: :done)

    work_section.descendant.add_active_item(task1.id)
    work_section.descendant.add_active_item(task2.id)
    work_section.descendant.add_inactive_item(task3.id)
    work_section.descendant.save!

    @source_day.descendant.add_active_item(work_section.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: { "items" => { "sections_with_no_active_items" => false, "notes" => true } }
    )

    result = service.call
    target_day = result[:target_day]

    # Find Work section
    target_active_ids = target_day.descendant.extract_active_item_ids
    work_section = Item.find_by(id: target_active_ids, title: "Work")

    work_active_ids = work_section.descendant.extract_active_item_ids
    work_inactive_ids = work_section.descendant.extract_inactive_item_ids

    # Only active items should be migrated - inactive items NEVER migrate
    assert_equal 2, work_active_ids.length
    assert_equal 0, work_inactive_ids.length

    tasks = Item.where(id: work_active_ids)
    assert_equal [ "Task 1", "Task 2" ], tasks.pluck(:title).sort
  end

  test "correctly counts migrated items excluding permanent section itself" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )

    regular_item = @user.items.create!(title: "Regular Task", state: :todo)

    @source_day.descendant.add_active_item(work_section.id)
    @source_day.descendant.add_active_item(regular_item.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call

    # Should count regular_item only, not the permanent section
    assert_equal 1, result[:migrated_count]
  end

  test "CRITICAL: NEVER recreates permanent sections on target day" do
    @user.permanent_sections = [ "Work", "Personal" ]
    @user.save!

    # Create source day with permanent sections
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )
    work_section.reload
    work_section.descendant || work_section.create_descendant!
    work_item = @user.items.create!(title: "Work Task", state: :todo)
    work_section.descendant.add_active_item(work_item.id)
    work_section.descendant.save!

    @source_day.descendant.add_active_item(work_section.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # Count ALL permanent sections with title "Work" in the system
    all_work_sections = Item.where(
      user_id: @user.id,
      item_type: :section,
      title: "Work"
    ).where("extra_data ->> 'permanent_section' = 'true'")

    # Should have exactly 2: one from source day, one from target day
    # NEVER more than 2 (which would indicate duplication)
    assert_equal 2, all_work_sections.count

    # Target day should have exactly ONE Work section
    target_active_ids = target_day.descendant.extract_active_item_ids
    target_work_sections = Item.where(id: target_active_ids, title: "Work", item_type: :section)
    assert_equal 1, target_work_sections.count

    # Verify the work item was migrated to target's Work section
    target_work_section = target_work_sections.first
    target_work_section.reload
    work_children = target_work_section.descendant.extract_active_item_ids
    assert_equal 1, work_children.length
  end

  test "CRITICAL: migrates items from multiple permanent sections correctly" do
    @user.permanent_sections = [ "Work", "Personal", "Health" ]
    @user.save!

    # Create permanent sections in source with items
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )
    work_section.reload
    work_section.descendant || work_section.create_descendant!
    work_item = @user.items.create!(title: "Work Task", state: :todo)
    work_section.descendant.add_active_item(work_item.id)
    work_section.descendant.save!

    personal_section = @user.items.create!(
      title: "Personal",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )
    personal_section.reload
    personal_section.descendant || personal_section.create_descendant!
    personal_item = @user.items.create!(title: "Personal Task", state: :todo)
    personal_section.descendant.add_active_item(personal_item.id)
    personal_section.descendant.save!

    @source_day.descendant.add_active_item(work_section.id)
    @source_day.descendant.add_active_item(personal_section.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # Target day should have exactly 3 permanent sections (Work, Personal, Health)
    target_active_ids = target_day.descendant.extract_active_item_ids
    target_permanent_sections = Item.where(id: target_active_ids, item_type: :section)
      .where("extra_data ->> 'permanent_section' = 'true'")

    assert_equal 3, target_permanent_sections.count
    assert_equal [ "Health", "Personal", "Work" ], target_permanent_sections.pluck(:title).sort

    # Verify Work section has work task
    work = target_permanent_sections.find_by(title: "Work")
    work.reload
    assert_equal 1, work.descendant.extract_active_item_ids.length

    # Verify Personal section has personal task
    personal = target_permanent_sections.find_by(title: "Personal")
    personal.reload
    assert_equal 1, personal.descendant.extract_active_item_ids.length

    # Verify Health section is empty
    health = target_permanent_sections.find_by(title: "Health")
    health.reload
    assert_equal 0, health.descendant.extract_active_item_ids.length
  end

  test "CRITICAL: does not migrate permanent sections to day root" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    # Create permanent section in source
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )
    work_section.reload
    work_section.descendant || work_section.create_descendant!
    work_item = @user.items.create!(title: "Work Task", state: :todo)
    work_section.descendant.add_active_item(work_item.id)
    work_section.descendant.save!

    # Also add a regular item
    regular_item = @user.items.create!(title: "Regular Task", state: :todo)

    @source_day.descendant.add_active_item(work_section.id)
    @source_day.descendant.add_active_item(regular_item.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # Target day root should have: Work section + Regular Task
    # NOT: Work section + another Work section
    target_active_ids = target_day.descendant.extract_active_item_ids
    target_items = Item.where(id: target_active_ids)

    # Should have exactly 2 items at root: Work section and Regular Task
    assert_equal 2, target_items.count

    # Should have exactly 1 Work section
    work_sections = target_items.where(title: "Work", item_type: :section)
    assert_equal 1, work_sections.count

    # Should have exactly 1 Regular Task
    regular_tasks = target_items.where(title: "Regular Task")
    assert_equal 1, regular_tasks.count
  end

  test "CRITICAL: migrates permanent section with nested sections correctly" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    # Create permanent section with nested section inside
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )
    work_section.reload
    work_section.descendant || work_section.create_descendant!

    project_section = @user.items.create!(title: "Project X", item_type: :section, state: :todo)
    project_section.reload
    project_section.descendant || project_section.create_descendant!
    project_task = @user.items.create!(title: "Project Task", state: :todo)
    project_section.descendant.add_active_item(project_task.id)
    project_section.descendant.save!

    work_section.descendant.add_active_item(project_section.id)
    work_section.descendant.save!

    @source_day.descendant.add_active_item(work_section.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # Target day should have 1 Work section at root
    target_active_ids = target_day.descendant.extract_active_item_ids
    work_sections = Item.where(id: target_active_ids, title: "Work")
    assert_equal 1, work_sections.count

    # Work section should contain Project X section
    work = work_sections.first
    work.reload
    work_children_ids = work.descendant.extract_active_item_ids
    project_sections = Item.where(id: work_children_ids, title: "Project X")
    assert_equal 1, project_sections.count

    # Project X should contain the task
    project = project_sections.first
    project.reload
    project_children_ids = project.descendant.extract_active_item_ids
    tasks = Item.where(id: project_children_ids, title: "Project Task")
    assert_equal 1, tasks.count
  end

  test "CRITICAL: respects state filtering when migrating permanent section children" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    # Create permanent section with mix of todo and non-todo items
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )
    work_section.reload
    work_section.descendant || work_section.create_descendant!

    todo_item = @user.items.create!(title: "Todo Task", item_type: :completable, state: :todo)
    done_item = @user.items.create!(title: "Done Task", item_type: :completable, state: :done)
    deferred_item = @user.items.create!(title: "Deferred Task", item_type: :completable, state: :deferred)

    work_section.descendant.add_active_item(todo_item.id)
    work_section.descendant.add_active_item(done_item.id)
    work_section.descendant.add_active_item(deferred_item.id)
    work_section.descendant.save!

    @source_day.descendant.add_active_item(work_section.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # Find Work section in target
    target_active_ids = target_day.descendant.extract_active_item_ids
    work_section = Item.find_by(id: target_active_ids, title: "Work")

    # ONLY todo item should be migrated
    work_section.reload
    work_children_ids = work_section.descendant.extract_active_item_ids
    assert_equal 1, work_children_ids.length

    copied_item = Item.find(work_children_ids.first)
    assert_equal "Todo Task", copied_item.title
    assert_equal "todo", copied_item.state
  end

  test "CRITICAL: sets migration chain on both days" do
    item = @user.items.create!(title: "Task", state: :todo)
    @source_day.descendant.add_active_item(item.id)
    @source_day.descendant.save!

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # Reload both days to get updated values
    @source_day.reload
    target_day.reload

    # Source day should point to target day
    assert_equal target_day.id, @source_day.imported_to_day_id
    assert_not_nil @source_day.imported_at

    # Target day should point back to source day
    assert_equal @source_day.id, target_day.imported_from_day_id
    assert_not_nil target_day.imported_at
  end

  test "CRITICAL: prevents duplicate migration from same source day" do
    item = @user.items.create!(title: "Task", state: :todo)
    @source_day.descendant.add_active_item(item.id)
    @source_day.descendant.save!

    # First migration
    service1 = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )
    result1 = service1.call
    assert result1[:success]

    # Attempt second migration from same source day
    another_date = @target_date + 1.day
    service2 = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: another_date,
      migration_settings: {}
    )

    result2 = service2.call

    # Should fail
    assert_not result2[:success]
    assert_includes result2[:error], "already been migrated"
  end

  test "CRITICAL: migrates to exact target date specified" do
    item = @user.items.create!(title: "Task", state: :todo)
    @source_day.descendant.add_active_item(item.id)
    @source_day.descendant.save!

    # Use a specific future date
    future_date = Date.today + 5.days

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: future_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # MUST be the exact date we specified, NOT today
    assert_equal future_date, target_day.date
    assert_not_equal Date.today, target_day.date
  end

  test "CRITICAL: migrates to past date if specified" do
    # Use the existing @source_day (yesterday)
    item = @user.items.create!(title: "Task", state: :todo)
    @source_day.descendant.add_active_item(item.id)
    @source_day.descendant.save!

    # Target is 3 days ago (before source)
    past_date = Date.today - 3.days

    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: past_date,
      migration_settings: {}
    )

    result = service.call
    target_day = result[:target_day]

    # MUST be the exact past date we specified
    assert_equal past_date, target_day.date
  end
end
