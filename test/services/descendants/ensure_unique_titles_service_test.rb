# frozen_string_literal: true

require "test_helper"

class Descendants::EnsureUniqueTitlesServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    # Descendant created automatically by after_create callback
    @day = @user.days.create!(date: Date.today, state: :open, skip_permanent_sections_callback: true)
    @descendant = @day.descendant
  end

  test "removes duplicate titles case-insensitive" do
    # Create items with duplicate titles (different cases)
    item1 = @user.items.create!(title: "Task", state: :todo)
    item2 = @user.items.create!(title: "task", state: :todo)
    item3 = @user.items.create!(title: "TASK", state: :todo)

    @descendant.add_active_item(item1.id)
    @descendant.add_active_item(item2.id)
    @descendant.add_active_item(item3.id)
    @descendant.save!

    service = Descendants::EnsureUniqueTitlesService.new(descendant: @descendant)
    result = service.call

    assert result[:success]
    assert_equal 2, result[:removed_count]
    assert_equal 2, result[:duplicates].length

    # Should only have 1 item left (the first one)
    @descendant.reload
    active_item_ids = @descendant.extract_active_item_ids
    assert_equal 1, active_item_ids.count
    assert_equal item1.id, active_item_ids.first
  end

  test "keeps first occurrence" do
    item1 = @user.items.create!(title: "Keep Me", state: :todo)
    item2 = @user.items.create!(title: "keep me", state: :todo)
    item3 = @user.items.create!(title: "KEEP ME", state: :todo)

    @descendant.add_active_item(item1.id)
    @descendant.add_active_item(item2.id)
    @descendant.add_active_item(item3.id)
    @descendant.save!

    service = Descendants::EnsureUniqueTitlesService.new(descendant: @descendant)
    service.call

    @descendant.reload
    active_item_ids = @descendant.extract_active_item_ids
    kept_item = Item.find(active_item_ids.first)

    # Should keep the first one with exact original title
    assert_equal "Keep Me", kept_item.title
  end

  test "Task, task, TASK keeps only first Task" do
    item1 = @user.items.create!(title: "Task", state: :todo)
    item2 = @user.items.create!(title: "task", state: :todo)
    item3 = @user.items.create!(title: "TASK", state: :todo)

    @descendant.add_active_item(item1.id)
    @descendant.add_active_item(item2.id)
    @descendant.add_active_item(item3.id)
    @descendant.save!

    service = Descendants::EnsureUniqueTitlesService.new(descendant: @descendant)
    result = service.call

    assert_equal 2, result[:removed_count]

    # Duplicates should list the removed items
    assert_equal 2, result[:duplicates].length
    removed_ids = result[:duplicates].map { |d| d[:id] }
    assert_includes removed_ids, item2.id
    assert_includes removed_ids, item3.id

    @descendant.reload
    active_item_ids = @descendant.extract_active_item_ids
    assert_equal [ item1.id ], active_item_ids
  end

  test "returns removed_count and duplicates array" do
    item1 = @user.items.create!(title: "A", state: :todo)
    item2 = @user.items.create!(title: "a", state: :todo)

    @descendant.add_active_item(item1.id)
    @descendant.add_active_item(item2.id)
    @descendant.save!

    service = Descendants::EnsureUniqueTitlesService.new(descendant: @descendant)
    result = service.call

    assert_equal 1, result[:removed_count]
    assert_equal 1, result[:duplicates].length
    assert_equal item2.id, result[:duplicates].first[:id]
    assert_equal "a", result[:duplicates].first[:title]
  end

  test "preserves order of kept items" do
    item1 = @user.items.create!(title: "First", state: :todo)
    item2 = @user.items.create!(title: "Second", state: :todo)
    item3 = @user.items.create!(title: "SECOND", state: :todo)
    item4 = @user.items.create!(title: "Third", state: :todo)

    @descendant.add_active_item(item1.id)
    @descendant.add_active_item(item2.id)
    @descendant.add_active_item(item3.id)
    @descendant.add_active_item(item4.id)
    @descendant.save!

    service = Descendants::EnsureUniqueTitlesService.new(descendant: @descendant)
    service.call

    @descendant.reload
    active_item_ids = @descendant.extract_active_item_ids

    # Should be in order: First, Second (kept), Third
    assert_equal [ item1.id, item2.id, item4.id ], active_item_ids
  end

  test "handles descendant with no duplicates" do
    item1 = @user.items.create!(title: "Unique1", state: :todo)
    item2 = @user.items.create!(title: "Unique2", state: :todo)

    @descendant.add_active_item(item1.id)
    @descendant.add_active_item(item2.id)
    @descendant.save!

    service = Descendants::EnsureUniqueTitlesService.new(descendant: @descendant)
    result = service.call

    assert result[:success]
    assert_equal 0, result[:removed_count]
    assert_equal [], result[:duplicates]

    # All items should remain
    @descendant.reload
    assert_equal 2, @descendant.extract_active_item_ids.count
  end

  test "handles empty descendant" do
    service = Descendants::EnsureUniqueTitlesService.new(descendant: @descendant)
    result = service.call

    assert result[:success]
    assert_equal 0, result[:removed_count]
    assert_equal [], result[:duplicates]
  end

  test "only checks active_items not inactive_items" do
    # Add duplicates to active items
    active_item1 = @user.items.create!(title: "Task", state: :todo)
    active_item2 = @user.items.create!(title: "task", state: :todo)

    # Add item with same title to inactive items
    inactive_item = @user.items.create!(title: "TASK", state: :done)

    @descendant.add_active_item(active_item1.id)
    @descendant.add_active_item(active_item2.id)
    @descendant.add_inactive_item(inactive_item.id)
    @descendant.save!

    service = Descendants::EnsureUniqueTitlesService.new(descendant: @descendant)
    result = service.call

    # Should only remove duplicate from active items
    assert_equal 1, result[:removed_count]

    @descendant.reload
    active_item_ids = @descendant.extract_active_item_ids
    inactive_item_ids = @descendant.extract_inactive_item_ids

    # Active should have 1 item
    assert_equal 1, active_item_ids.count

    # Inactive should still have its item
    assert_equal 1, inactive_item_ids.count
    assert_equal inactive_item.id, inactive_item_ids.first
  end

  test "handles nil descendant gracefully" do
    service = Descendants::EnsureUniqueTitlesService.new(descendant: nil)
    result = service.call

    assert result[:success]
    assert_equal 0, result[:removed_count]
    assert_equal [], result[:duplicates]
  end

  # Transaction rollback is handled by Rails ActiveRecord::Base.transaction
  # and is well-tested by Rails itself. We rely on this built-in behavior.

  test "handles complex scenario with multiple duplicates" do
    # Create: A, a, B, b, C, c
    items = [
      @user.items.create!(title: "A", state: :todo),
      @user.items.create!(title: "a", state: :todo),
      @user.items.create!(title: "B", state: :todo),
      @user.items.create!(title: "b", state: :todo),
      @user.items.create!(title: "C", state: :todo),
      @user.items.create!(title: "c", state: :todo)
    ]

    items.each { |item| @descendant.add_active_item(item.id) }
    @descendant.save!

    service = Descendants::EnsureUniqueTitlesService.new(descendant: @descendant)
    result = service.call

    assert_equal 3, result[:removed_count] # Removes a, b, c

    @descendant.reload
    active_item_ids = @descendant.extract_active_item_ids
    assert_equal 3, active_item_ids.count # Keeps A, B, C

    kept_items = Item.where(id: active_item_ids)
    assert_equal [ "A", "B", "C" ], kept_items.pluck(:title)
  end
end
