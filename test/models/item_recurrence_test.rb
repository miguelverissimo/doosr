# frozen_string_literal: true

require "test_helper"

class ItemRecurrenceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @today_day = @user.days.create!(date: Date.today, state: :open)
  end

  test "has_recurrence? returns true when recurrence_rule is present" do
    item = @user.items.create!(
      title: "Recurring task",
      recurrence_rule: { frequency: "daily" }.to_json
    )

    assert item.has_recurrence?
  end

  test "has_recurrence? returns false when recurrence_rule is nil" do
    item = @user.items.create!(title: "Non-recurring task")

    assert_not item.has_recurrence?
  end

  test "completing a recurring item schedules next occurrence" do
    item = @user.items.create!(
      title: "Daily task",
      item_type: :completable,
      state: :todo,
      recurrence_rule: { frequency: "daily" }.to_json
    )
    @today_day.descendant.add_active_item(item.id)
    @today_day.descendant.save!

    # Complete the item
    item.set_done!

    # Reload to get updated recurring_next_item_id
    item.reload

    # Check that next occurrence was scheduled
    assert_not_nil item.recurring_next_item_id
    next_item = Item.find(item.recurring_next_item_id)

    assert_equal "Daily task", next_item.title
    assert_equal "todo", next_item.state
    assert_equal item.recurrence_rule, next_item.recurrence_rule

    # Check that next item is in tomorrow's day
    tomorrow_day = @user.days.find_by(date: Date.tomorrow)
    assert_not_nil tomorrow_day
    assert_includes tomorrow_day.descendant.extract_active_item_ids, next_item.id
  end

  test "uncompleting a recurring item deletes the next occurrence" do
    item = @user.items.create!(
      title: "Daily task",
      item_type: :completable,
      state: :todo,
      recurrence_rule: { frequency: "daily" }.to_json
    )
    @today_day.descendant.add_active_item(item.id)
    @today_day.descendant.save!

    # Complete the item to create next occurrence
    item.set_done!
    item.reload

    next_item_id = item.recurring_next_item_id
    assert_not_nil next_item_id

    # Verify next item exists
    assert Item.exists?(next_item_id)

    # Uncomplete the item
    item.set_todo!
    item.reload

    # Check that recurring_next_item_id is cleared
    assert_nil item.recurring_next_item_id

    # Check that next item was hard deleted
    assert_not Item.exists?(next_item_id)
  end

  test "uncompleting removes next item from descendant arrays" do
    item = @user.items.create!(
      title: "Daily task",
      item_type: :completable,
      state: :todo,
      recurrence_rule: { frequency: "daily" }.to_json
    )
    @today_day.descendant.add_active_item(item.id)
    @today_day.descendant.save!

    # Complete the item
    item.set_done!
    item.reload

    next_item_id = item.recurring_next_item_id
    tomorrow_day = @user.days.find_by(date: Date.tomorrow)

    # Verify next item is in tomorrow's day
    assert_includes tomorrow_day.descendant.extract_active_item_ids, next_item_id

    # Uncomplete the item
    item.set_todo!

    # Reload tomorrow's day descendant
    tomorrow_day.reload

    # Verify next item is not in tomorrow's day anymore
    assert_not_includes tomorrow_day.descendant.extract_active_item_ids, next_item_id
    assert_not_includes tomorrow_day.descendant.extract_inactive_item_ids, next_item_id
  end

  test "completing a non-recurring item does not schedule next occurrence" do
    item = @user.items.create!(
      title: "Non-recurring task",
      item_type: :completable,
      state: :todo
    )
    @today_day.descendant.add_active_item(item.id)
    @today_day.descendant.save!

    # Complete the item
    item.set_done!
    item.reload

    # Check that no next occurrence was scheduled
    assert_nil item.recurring_next_item_id

    # Check that no day was created for tomorrow
    tomorrow_day = @user.days.find_by(date: Date.tomorrow)
    # Day might exist for other reasons, but it should be empty or not exist
    if tomorrow_day
      # If it exists, it should not have any items related to our task
      all_items = tomorrow_day.descendant.extract_active_item_ids +
                  tomorrow_day.descendant.extract_inactive_item_ids
      # No items should be copies of our item
      items = Item.where(id: all_items, title: item.title)
      assert_equal 0, items.count
    end
  end

  test "completing weekly recurring item schedules for correct day" do
    # Set today as Monday (wday = 1)
    travel_to Date.new(2025, 1, 13) do # Monday
      item = @user.items.create!(
        title: "Monday/Friday task",
        item_type: :completable,
        state: :todo,
        recurrence_rule: { frequency: "weekly", days_of_week: [1, 5] }.to_json
      )
      @today_day.update!(date: Date.today)
      @today_day.descendant.add_active_item(item.id)
      @today_day.descendant.save!

      # Complete the item on Monday
      item.set_done!
      item.reload

      # Should schedule for Friday (next occurrence)
      next_item = Item.find(item.recurring_next_item_id)
      friday = Date.new(2025, 1, 17) # Friday

      friday_day = @user.days.find_by(date: friday)
      assert_not_nil friday_day
      assert_includes friday_day.descendant.extract_active_item_ids, next_item.id
    end
  end

  test "completing every_n_days recurring item schedules correctly" do
    item = @user.items.create!(
      title: "Every 3 days task",
      item_type: :completable,
      state: :todo,
      recurrence_rule: { frequency: "every_n_days", interval: 3 }.to_json
    )
    @today_day.descendant.add_active_item(item.id)
    @today_day.descendant.save!

    # Complete the item
    item.set_done!
    item.reload

    # Should schedule for 3 days from today
    next_item = Item.find(item.recurring_next_item_id)
    target_date = Date.today + 3.days

    target_day = @user.days.find_by(date: target_date)
    assert_not_nil target_day
    assert_includes target_day.descendant.extract_active_item_ids, next_item.id
  end

  test "completing monthly recurring item schedules for next month" do
    item = @user.items.create!(
      title: "Monthly task",
      item_type: :completable,
      state: :todo,
      recurrence_rule: { frequency: "monthly" }.to_json
    )
    @today_day.descendant.add_active_item(item.id)
    @today_day.descendant.save!

    # Complete the item
    item.set_done!
    item.reload

    # Should schedule for same day next month
    next_item = Item.find(item.recurring_next_item_id)
    target_date = Date.today.next_month

    target_day = @user.days.find_by(date: target_date)
    assert_not_nil target_day
    assert_includes target_day.descendant.extract_active_item_ids, next_item.id
  end

  test "uncompleting item without next occurrence does not error" do
    item = @user.items.create!(
      title: "Task",
      item_type: :completable,
      state: :done
    )

    # Should not raise error
    assert_nothing_raised do
      item.set_todo!
    end

    item.reload
    assert_nil item.recurring_next_item_id
  end

  test "recurrence preserves item_type" do
    item = @user.items.create!(
      title: "Recurring completable",
      item_type: :completable,
      state: :todo,
      recurrence_rule: { frequency: "daily" }.to_json
    )
    @today_day.descendant.add_active_item(item.id)
    @today_day.descendant.save!

    item.set_done!
    item.reload

    next_item = Item.find(item.recurring_next_item_id)
    assert_equal "completable", next_item.item_type
  end
end
