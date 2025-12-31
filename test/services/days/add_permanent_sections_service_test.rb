# frozen_string_literal: true

require "test_helper"

class Days::AddPermanentSectionsServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    # Descendant created automatically by after_create callback
    @day = @user.days.create!(date: Date.today, state: :open, skip_permanent_sections_callback: true)
  end

  test "adds all permanent sections to empty day" do
    @user.permanent_sections = [ "Work", "Personal", "Health" ]
    @user.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    result = service.call

    assert result[:success]
    assert_equal 3, result[:sections_added]

    @day.reload
    active_item_ids = @day.descendant.extract_active_item_ids
    sections = Item.where(id: active_item_ids, item_type: :section)

    assert_equal 3, sections.count
    assert_equal [ "Health", "Personal", "Work" ], sections.pluck(:title).sort
  end

  test "skips sections that already exist with exact case match" do
    @user.permanent_sections = [ "Work", "Personal" ]
    @user.save!

    # Pre-create "Work" section
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo,
      extra_data: { permanent_section: true }
    )
    @day.descendant.add_active_item(work_section.id)
    @day.descendant.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    result = service.call

    assert result[:success]
    assert_equal 1, result[:sections_added] # Only Personal should be added

    @day.reload
    active_item_ids = @day.descendant.extract_active_item_ids
    assert_equal 2, active_item_ids.count # Work + Personal
  end

  test "CRITICAL: skips sections with case-insensitive title match" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    # Pre-create "work" (lowercase) section
    work_section = @user.items.create!(
      title: "work",
      item_type: :section,
      state: :todo
    )
    @day.descendant.add_active_item(work_section.id)
    @day.descendant.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    result = service.call

    assert result[:success]
    assert_equal 0, result[:sections_added] # Should skip "Work" because "work" exists

    @day.reload
    active_item_ids = @day.descendant.extract_active_item_ids
    assert_equal 1, active_item_ids.count # Only the existing "work"
  end

  test "CRITICAL: Work on day does not add work from permanent sections" do
    @user.permanent_sections = [ "work" ]
    @user.save!

    # Day already has "Work" (capital W)
    work_section = @user.items.create!(
      title: "Work",
      item_type: :section,
      state: :todo
    )
    @day.descendant.add_active_item(work_section.id)
    @day.descendant.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    result = service.call

    assert result[:success]
    assert_equal 0, result[:sections_added]

    @day.reload
    active_item_ids = @day.descendant.extract_active_item_ids
    assert_equal 1, active_item_ids.count
  end

  test "CRITICAL: work on day does not add Work from permanent sections" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    # Day already has "work" (lowercase w)
    work_section = @user.items.create!(
      title: "work",
      item_type: :section,
      state: :todo
    )
    @day.descendant.add_active_item(work_section.id)
    @day.descendant.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    result = service.call

    assert result[:success]
    assert_equal 0, result[:sections_added]

    @day.reload
    active_item_ids = @day.descendant.extract_active_item_ids
    assert_equal 1, active_item_ids.count
  end

  test "returns sections_added count correctly" do
    @user.permanent_sections = [ "A", "B", "C", "D", "E" ]
    @user.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    result = service.call

    assert_equal 5, result[:sections_added]
  end

  test "creates descendant for each section" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    service.call

    @day.reload
    active_item_ids = @day.descendant.extract_active_item_ids
    section = Item.find(active_item_ids.first)

    assert_not_nil section.descendant
    assert_equal [], section.descendant.active_items
    assert_equal [], section.descendant.inactive_items
  end

  test "adds sections to day active_items in correct order" do
    @user.permanent_sections = [ "Third", "First", "Second" ]
    @user.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    service.call

    @day.reload
    active_item_ids = @day.descendant.extract_active_item_ids
    items = Item.where(id: active_item_ids).index_by(&:id)
    ordered_titles = active_item_ids.map { |id| items[id].title }

    assert_equal [ "Third", "First", "Second" ], ordered_titles
  end

  test "idempotent: calling twice adds nothing on second call" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)

    # First call
    result1 = service.call
    assert_equal 1, result1[:sections_added]

    # Second call
    service2 = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    result2 = service2.call
    assert_equal 0, result2[:sections_added]

    # Should still have exactly 1 section
    @day.reload
    active_item_ids = @day.descendant.extract_active_item_ids
    assert_equal 1, active_item_ids.count
  end

  test "handles user with no permanent sections" do
    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    result = service.call

    assert result[:success]
    assert_equal 0, result[:sections_added]
  end

  test "sets permanent_section marker in extra_data" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    service.call

    @day.reload
    active_item_ids = @day.descendant.extract_active_item_ids
    section = Item.find(active_item_ids.first)

    assert section.extra_data&.dig("permanent_section")
  end

  # Transaction rollback is handled by Rails ActiveRecord::Base.transaction
  # and is well-tested by Rails itself. We rely on this built-in behavior.

  test "handles day without descendant gracefully" do
    # This shouldn't happen in practice, but let's handle it
    @day.descendant.destroy if @day.descendant

    @user.permanent_sections = [ "Work" ]
    @user.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    result = service.call

    # Should fail gracefully
    assert_not result[:success]
  end

  test "works with closed days" do
    @day.close!
    @user.permanent_sections = [ "Work" ]
    @user.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    result = service.call

    assert result[:success]
    assert_equal 1, result[:sections_added]

    # Day should still be closed
    @day.reload
    assert_equal "closed", @day.state
  end

  test "handles mixed case variations in title" do
    @user.permanent_sections = [ "WORK" ]
    @user.save!

    # Day has "WoRk"
    existing = @user.items.create!(title: "WoRk", item_type: :section, state: :todo)
    @day.descendant.add_active_item(existing.id)
    @day.descendant.save!

    service = Days::AddPermanentSectionsService.new(day: @day, user: @user)
    result = service.call

    assert result[:success]
    assert_equal 0, result[:sections_added]
  end
end
