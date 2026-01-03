# frozen_string_literal: true

require "test_helper"

class Days::ImportDebugTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @source_date = Date.parse("2026-01-02")
    @target_date = Date.parse("2026-01-03")
  end

  test "DEBUG: Trace through production scenario - 3 permanent sections, verify no duplication" do
    # Set up user with 3 permanent sections (like production)
    @user.permanent_sections = [ "Work", "Personal", "Health" ]
    @user.save!

    # === CREATE SOURCE DAY (2026-01-02) ===
    # This simulates what happened when Day 3 was opened
    source_result = Days::DayOpeningService.new(user: @user, date: @source_date).call
    @source_day = source_result[:day]

    puts "\n=== SOURCE DAY (Day 3) AFTER OPENING ==="
    source_active_ids = @source_day.descendant.extract_active_item_ids
    source_items = Item.where(id: source_active_ids)
    puts "Active items count: #{source_items.count}"
    source_items.each do |item|
      puts "  Item #{item.id}: #{item.title} (#{item.item_type}) - permanent: #{item.extra_data&.dig('permanent_section')}"
    end

    # Add some tasks to permanent sections
    work_section = source_items.find_by(title: "Work")
    work_section.reload
    work_task = @user.items.create!(title: "Work Task", state: :todo)
    work_section.descendant.add_active_item(work_task.id)
    work_section.descendant.save!

    # Close the source day
    @source_day.close!

    puts "\n=== SOURCE DAY (Day 3) AFTER ADDING TASKS AND CLOSING ==="
    @source_day.reload
    source_active_ids = @source_day.descendant.extract_active_item_ids
    source_items = Item.where(id: source_active_ids)
    puts "Active items count: #{source_items.count}"
    source_items.each do |item|
      puts "  Item #{item.id}: #{item.title} (#{item.item_type}) - permanent: #{item.extra_data&.dig('permanent_section')}"
      if item.descendant
        child_ids = item.descendant.extract_active_item_ids
        if child_ids.any?
          Item.where(id: child_ids).each do |child|
            puts "    Child #{child.id}: #{child.title} (#{child.item_type})"
          end
        end
      end
    end

    # === MIGRATE TO TARGET DAY (2026-01-03) ===
    puts "\n=== RUNNING MIGRATION FROM #{@source_date} TO #{@target_date} ==="
    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    assert result[:success], "Migration should succeed"
    @target_day = result[:target_day]

    puts "\n=== TARGET DAY (Day 8) AFTER MIGRATION ==="
    @target_day.reload
    target_active_ids = @target_day.descendant.extract_active_item_ids
    target_items = Item.where(id: target_active_ids)
    puts "Active items count: #{target_items.count}"
    puts "Migrated count reported: #{result[:migrated_count]}"
    target_items.each do |item|
      puts "  Item #{item.id}: #{item.title} (#{item.item_type}) - permanent: #{item.extra_data&.dig('permanent_section')} - source: #{item.source_item_id}"
      if item.descendant
        child_ids = item.descendant.extract_active_item_ids
        if child_ids.any?
          Item.where(id: child_ids).each do |child|
            puts "    Child #{child.id}: #{child.title} (#{child.item_type}) - source: #{child.source_item_id}"
          end
        end
      end
    end

    # === VERIFICATION ===
    puts "\n=== VERIFICATION ==="

    # Count permanent sections with each title in the ENTIRE SYSTEM
    [ "Work", "Personal", "Health" ].each do |title|
      all_sections = Item.where(
        user_id: @user.id,
        item_type: :section,
        title: title
      ).where("extra_data ->> 'permanent_section' = 'true'")
      puts "Total '#{title}' permanent sections in system: #{all_sections.count}"
      all_sections.each do |section|
        day_id = Descendant.where("active_items @> ?", [ { "Item" => section.id } ].to_json)
                           .where(descendable_type: "Day")
                           .first&.descendable_id
        day = Day.find_by(id: day_id)
        puts "  Section #{section.id} on Day #{day&.date || 'NONE'}"
      end
    end

    # Count permanent sections in target day ONLY
    target_permanent_sections = target_items.where(item_type: :section)
                                           .where("extra_data ->> 'permanent_section' = 'true'")
    puts "\nPermanent sections in target day: #{target_permanent_sections.count}"
    puts "Expected: 3 (Work, Personal, Health)"

    # CRITICAL ASSERTIONS
    assert_equal 3, target_permanent_sections.count,
                 "Target day should have exactly 3 permanent sections"

    assert_equal [ "Health", "Personal", "Work" ], target_permanent_sections.pluck(:title).sort,
                 "Target day should have Work, Personal, Health sections"

    # Verify NO duplicate sections (each title should appear exactly once in target day)
    target_items.where(item_type: :section).group(:title).count.each do |title, count|
      assert_equal 1, count, "Section '#{title}' appears #{count} times in target day (should be 1)"
    end

    # Verify Work section has the migrated task
    target_work_section = target_permanent_sections.find_by(title: "Work")
    target_work_section.reload
    work_children_ids = target_work_section.descendant.extract_active_item_ids
    assert_equal 1, work_children_ids.length, "Work section should have 1 child task"

    work_child = Item.find(work_children_ids.first)
    assert_equal "Work Task", work_child.title
    assert_equal work_task.id, work_child.source_item_id,
                 "Migrated task should reference source task"
  end

  test "CRITICAL: Production scenario - verify NO section duplication with detailed logging" do
    # Exactly replicate production scenario
    @user.permanent_sections = [ "Work", "Personal", "Health" ]
    @user.save!

    # Create and close source day
    source_result = Days::DayOpeningService.new(user: @user, date: @source_date).call
    @source_day = source_result[:day]

    # Add tasks to each permanent section
    source_active_ids = @source_day.descendant.extract_active_item_ids
    source_sections = Item.where(id: source_active_ids, item_type: :section)

    puts "\n=== BEFORE ADDING TASKS TO SECTIONS ==="
    source_sections.each do |section|
      puts "Section #{section.id}: #{section.title}"
    end

    source_sections.each_with_index do |section, idx|
      section.reload
      task = @user.items.create!(title: "#{section.title} Task #{idx + 1}", state: :todo)
      puts "Created task #{task.id}: #{task.title} (state: #{task.state})"
      section.descendant.add_active_item(task.id)
      section.descendant.save!
      puts "  Added to section #{section.id} descendant"

      # Verify it was added
      section.reload
      child_ids = section.descendant.extract_active_item_ids
      puts "  Section #{section.id} now has #{child_ids.length} children: #{child_ids.inspect}"
    end

    @source_day.close!
    @source_day.reload

    puts "\n=== SOURCE DAY AFTER CLOSING ==="
    source_active_ids = @source_day.descendant.extract_active_item_ids
    puts "Source day has #{source_active_ids.length} active items"
    Item.where(id: source_active_ids).each do |item|
      puts "  Item #{item.id}: #{item.title} (#{item.item_type}, state: #{item.state})"
      if item.descendant
        child_ids = item.descendant.extract_active_item_ids
        if child_ids.any?
          Item.where(id: child_ids).each do |child|
            puts "    Child #{child.id}: #{child.title} (state: #{child.state})"
          end
        end
      end
    end

    # Count items before migration
    source_total_items = @source_day.descendant.extract_active_item_ids.length
    source_permanent_sections_count = source_sections.count

    # Perform migration
    puts "\n=== PERFORMING MIGRATION ==="
    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    assert result[:success], "Migration failed: #{result[:error]}"
    @target_day = result[:target_day]
    @target_day.reload

    puts "\n=== TARGET DAY AFTER MIGRATION ==="
    # Count items after migration
    target_active_ids = @target_day.descendant.extract_active_item_ids
    target_items = Item.where(id: target_active_ids)
    puts "Target day has #{target_active_ids.length} active items"
    target_items.each do |item|
      puts "  Item #{item.id}: #{item.title} (#{item.item_type}, state: #{item.state})"
      if item.descendant
        child_ids = item.descendant.extract_active_item_ids
        if child_ids.any?
          Item.where(id: child_ids).each do |child|
            puts "    Child #{child.id}: #{child.title} (state: #{child.state})"
          end
        else
          puts "    (no children)"
        end
      end
    end

    target_permanent_sections = target_items.where(item_type: :section)
                                           .where("extra_data ->> 'permanent_section' = 'true'")

    # CRITICAL: Target day should have EXACTLY 3 permanent sections (not 6!)
    assert_equal 3, target_permanent_sections.count,
                 "FAILED: Target day has #{target_permanent_sections.count} permanent sections (expected 3). " \
                 "This indicates permanent section duplication!"

    # CRITICAL: Target day ROOT should have ONLY 3 sections (tasks are nested inside sections)
    # NOT 3 sections + 3 tasks = 6 items (tasks should be inside sections)
    # NOT 6 sections + 3 tasks = 9 items (would indicate section duplication)
    assert_equal 3, target_active_ids.length,
                 "Target day ROOT should have 3 items (the 3 permanent sections), " \
                 "but has #{target_active_ids.length}. Tasks should be nested inside sections, not at root."

    # Verify tasks were migrated INSIDE the sections
    total_task_count = 0
    target_permanent_sections.each do |section|
      section.reload
      child_ids = section.descendant.extract_active_item_ids
      total_task_count += child_ids.length
    end
    assert_equal 3, total_task_count,
                 "Should have 3 tasks total (1 per section) nested inside permanent sections, " \
                 "but found #{total_task_count}"

    # Verify each section appears exactly once AT THE ROOT
    section_counts = target_items.where(item_type: :section).group(:title).count
    section_counts.each do |title, count|
      assert_equal 1, count,
                   "DUPLICATE DETECTED: Section '#{title}' appears #{count} times at target day ROOT!"
    end

    # CRITICAL: Verify permanent sections are NOT being copied/duplicated
    # Count ALL sections with permanent_section flag at root
    root_permanent_sections = target_items.where(item_type: :section)
                                         .where("extra_data ->> 'permanent_section' = 'true'")
    assert_equal 3, root_permanent_sections.count,
                 "Target day root should have exactly 3 permanent sections, " \
                 "but has #{root_permanent_sections.count}"

    # Count ALL sections at root (permanent + non-permanent)
    all_root_sections = target_items.where(item_type: :section)
    assert_equal 3, all_root_sections.count,
                 "Target day root should have exactly 3 sections total (all permanent), " \
                 "but has #{all_root_sections.count}. " \
                 "Extra sections indicate permanent sections were duplicated!"

    # Verify TOTAL permanent sections across entire system
    # Should be 6 total: 3 from source day + 3 from target day
    all_permanent_sections = Item.where(
      user_id: @user.id,
      item_type: :section
    ).where("extra_data ->> 'permanent_section' = 'true'")

    assert_equal 6, all_permanent_sections.count,
                 "System should have 6 total permanent sections (3 source + 3 target), " \
                 "but has #{all_permanent_sections.count}"

    # Count by title
    all_permanent_sections.group(:title).count.each do |title, count|
      assert_equal 2, count,
                   "Should have exactly 2 '#{title}' sections (1 source + 1 target), but have #{count}"
    end
  end

  test "CRITICAL: Verify permanent sections are NOT added to target day root during migration" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    # Create source day with Work section containing a task
    source_result = Days::DayOpeningService.new(user: @user, date: @source_date).call
    @source_day = source_result[:day]

    work_section = Item.find_by(
      user_id: @user.id,
      title: "Work",
      item_type: :section
    )
    work_section.reload
    work_task = @user.items.create!(title: "Work Task", state: :todo)
    work_section.descendant.add_active_item(work_task.id)
    work_section.descendant.save!

    # Also add a regular non-section item to source day root
    regular_task = @user.items.create!(title: "Regular Task", state: :todo)
    @source_day.descendant.add_active_item(regular_task.id)
    @source_day.descendant.save!

    @source_day.close!

    # Migrate to target
    service = Days::DayMigrationService.new(
      user: @user,
      source_day: @source_day,
      target_date: @target_date,
      migration_settings: {}
    )

    result = service.call
    @target_day = result[:target_day]
    @target_day.reload

    # Target day root should have: 1 Work section + 1 Regular Task = 2 items
    # NOT: 1 Work section + 1 duplicate Work section + 1 Regular Task = 3 items
    target_root_ids = @target_day.descendant.extract_active_item_ids
    target_root_items = Item.where(id: target_root_ids)

    assert_equal 2, target_root_ids.length,
                 "Target day root should have 2 items (1 section + 1 task), " \
                 "but has #{target_root_ids.length}"

    # Verify exactly 1 Work section at root
    work_sections_at_root = target_root_items.where(title: "Work", item_type: :section)
    assert_equal 1, work_sections_at_root.count,
                 "DUPLICATE: Found #{work_sections_at_root.count} Work sections at target day root"

    # Verify Work section contains the migrated task
    target_work = work_sections_at_root.first
    target_work.reload
    work_children_ids = target_work.descendant.extract_active_item_ids
    assert_equal 1, work_children_ids.length,
                 "Work section should have 1 child"

    # Verify the regular task was migrated to root
    regular_tasks_at_root = target_root_items.where.not(item_type: :section)
    assert_equal 1, regular_tasks_at_root.count
    assert_equal "Regular Task", regular_tasks_at_root.first.title
  end
end
