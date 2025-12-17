# frozen_string_literal: true

require "test_helper"

module Items
  class ScheduleNextOccurrenceServiceTest < ActiveSupport::TestCase
    setup do
      @user = User.create!(
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
      @today_day = @user.days.create!(date: Date.today, state: :open)
    end

    test "schedules next occurrence for daily recurrence" do
      item = @user.items.create!(
        title: "Daily task",
        item_type: :completable,
        state: :done,
        recurrence_rule: { frequency: "daily" }.to_json
      )

      service = ScheduleNextOccurrenceService.new(completed_item: item, user: @user)
      result = service.call

      assert result[:success]
      assert_not_nil result[:new_item]

      new_item = result[:new_item]
      assert_equal "Daily task", new_item.title
      assert_equal "todo", new_item.state
      assert_equal item.recurrence_rule, new_item.recurrence_rule
      assert_equal @user.id, new_item.user_id

      # Check that the new item is in tomorrow's day
      tomorrow_day = @user.days.find_by(date: Date.tomorrow)
      assert_not_nil tomorrow_day
      assert_includes tomorrow_day.descendant.extract_active_item_ids, new_item.id

      # Check that the completed item links to the new item
      item.reload
      assert_equal new_item.id, item.recurring_next_item_id
    end

    test "schedules next occurrence for weekly recurrence" do
      # Assuming today is a weekday, set recurrence for Monday and Friday
      item = @user.items.create!(
        title: "Weekly task",
        item_type: :completable,
        state: :done,
        recurrence_rule: { frequency: "weekly", days_of_week: [1, 5] }.to_json
      )

      service = ScheduleNextOccurrenceService.new(completed_item: item, user: @user)
      result = service.call

      assert result[:success]
      assert_not_nil result[:new_item]

      new_item = result[:new_item]
      assert_equal "Weekly task", new_item.title
      assert_equal "todo", new_item.state
    end

    test "preserves extra_data in next occurrence" do
      item = @user.items.create!(
        title: "Task with data",
        item_type: :completable,
        state: :done,
        recurrence_rule: { frequency: "daily" }.to_json,
        extra_data: { custom_field: "value" }
      )

      service = ScheduleNextOccurrenceService.new(completed_item: item, user: @user)
      result = service.call

      assert result[:success]
      new_item = result[:new_item]
      assert_equal({ "custom_field" => "value" }, new_item.extra_data)
    end

    test "returns error when item has no recurrence rule" do
      item = @user.items.create!(
        title: "Non-recurring task",
        item_type: :completable,
        state: :done
      )

      service = ScheduleNextOccurrenceService.new(completed_item: item, user: @user)
      result = service.call

      assert_not result[:success]
      assert_equal "Item does not have a recurrence rule", result[:error]
    end

    test "creates target day if it doesn't exist" do
      item = @user.items.create!(
        title: "Daily task",
        item_type: :completable,
        state: :done,
        recurrence_rule: { frequency: "daily" }.to_json
      )

      # Ensure tomorrow's day doesn't exist
      tomorrow_day = @user.days.find_by(date: Date.tomorrow)
      tomorrow_day&.destroy!

      service = ScheduleNextOccurrenceService.new(completed_item: item, user: @user)
      result = service.call

      assert result[:success]

      # Check that tomorrow's day was created
      tomorrow_day = @user.days.find_by(date: Date.tomorrow)
      assert_not_nil tomorrow_day
      assert_not_nil tomorrow_day.descendant
    end

    test "places item in permanent section if source item is in permanent section" do
      # Set up permanent sections for user
      @user.update!(permanent_sections: ["Morning Routine", "Work"])

      # Create permanent section on today's day
      morning_section = @user.items.create!(
        title: "Morning Routine",
        item_type: :section,
        state: :todo,
        extra_data: { permanent_section: true }
      )
      @today_day.descendant.add_active_item(morning_section.id)
      @today_day.descendant.save!

      # Create item in permanent section
      item = @user.items.create!(
        title: "Daily task in section",
        item_type: :completable,
        state: :done,
        recurrence_rule: { frequency: "daily" }.to_json
      )
      morning_section.descendant.add_active_item(item.id)
      morning_section.descendant.save!

      service = ScheduleNextOccurrenceService.new(completed_item: item, user: @user)
      result = service.call

      assert result[:success]
      new_item = result[:new_item]

      # Check that permanent section exists on tomorrow's day
      tomorrow_day = @user.days.find_by(date: Date.tomorrow)
      tomorrow_section = tomorrow_day.descendant.extract_active_item_ids
                                      .map { |id| Item.find(id) }
                                      .find { |i| i.section? && i.title == "Morning Routine" }

      assert_not_nil tomorrow_section
      assert_includes tomorrow_section.descendant.extract_active_item_ids, new_item.id
    end

    test "handles every_n_days recurrence" do
      item = @user.items.create!(
        title: "Every 3 days task",
        item_type: :completable,
        state: :done,
        recurrence_rule: { frequency: "every_n_days", interval: 3 }.to_json
      )

      service = ScheduleNextOccurrenceService.new(completed_item: item, user: @user)
      result = service.call

      assert result[:success]
      new_item = result[:new_item]

      # Check that the new item is 3 days from today
      target_day = @user.days.find_by(date: Date.today + 3.days)
      assert_not_nil target_day
      assert_includes target_day.descendant.extract_active_item_ids, new_item.id
    end

    test "handles monthly recurrence" do
      item = @user.items.create!(
        title: "Monthly task",
        item_type: :completable,
        state: :done,
        recurrence_rule: { frequency: "monthly" }.to_json
      )

      service = ScheduleNextOccurrenceService.new(completed_item: item, user: @user)
      result = service.call

      assert result[:success]
      new_item = result[:new_item]

      # Check that the new item is in next month
      next_month_date = Date.today.next_month
      target_day = @user.days.find_by(date: next_month_date)
      assert_not_nil target_day
      assert_includes target_day.descendant.extract_active_item_ids, new_item.id
    end
  end
end
