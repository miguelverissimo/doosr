# frozen_string_literal: true

require "test_helper"

class Days::DayOpeningServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @date = Date.today
  end

  test "creates new day with permanent sections" do
    @user.permanent_sections = [ "Work", "Personal", "Health" ]
    @user.save!

    service = Days::DayOpeningService.new(user: @user, date: @date)
    result = service.call

    assert result[:success]
    assert result[:created]
    assert_not result[:reopened]
    assert_not_nil result[:day]

    day = result[:day]
    assert_equal @date, day.date
    assert_equal "open", day.state

    # Check permanent sections were created
    active_item_ids = day.descendant.extract_active_item_ids
    sections = Item.where(id: active_item_ids, item_type: :section)

    assert_equal 3, sections.count
    assert_equal [ "Health", "Personal", "Work" ], sections.pluck(:title).sort

    sections.each do |section|
      assert section.extra_data&.dig("permanent_section")
      assert_not_nil section.descendant
    end
  end

  test "creates descendant automatically" do
    service = Days::DayOpeningService.new(user: @user, date: @date)
    result = service.call

    assert result[:success]
    assert_not_nil result[:day].descendant
    assert_equal [], result[:day].descendant.active_items
    assert_equal [], result[:day].descendant.inactive_items
  end

  test "skips permanent section creation when user has none configured" do
    service = Days::DayOpeningService.new(user: @user, date: @date)
    result = service.call

    assert result[:success]
    assert_equal 0, result[:day].descendant.extract_active_item_ids.count
  end

  test "returns existing open day without changes" do
    # Descendant is created automatically by after_create callback
    existing_day = @user.days.create!(date: @date, state: :open)

    service = Days::DayOpeningService.new(user: @user, date: @date)
    result = service.call

    assert result[:success]
    assert_not result[:created]
    assert_not result[:reopened]
    assert_equal existing_day.id, result[:day].id
  end

  test "reopens closed day WITHOUT adding permanent sections" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    # Create closed day without permanent sections (to test that reopening doesn't add them)
    # Descendant created automatically by after_create callback
    day = @user.days.create!(
      date: @date,
      state: :closed,
      closed_at: 1.hour.ago,
      skip_permanent_sections_callback: true
    )

    service = Days::DayOpeningService.new(user: @user, date: @date)
    result = service.call

    assert result[:success]
    assert_not result[:created]
    assert result[:reopened]
    assert_equal day.id, result[:day].id

    # Day should be open now
    day.reload
    assert_equal "open", day.state
    assert_not_nil day.reopened_at
    assert_nil day.closed_at

    # CRITICAL: No sections should be added when reopening
    active_item_ids = day.descendant.extract_active_item_ids
    assert_equal 0, active_item_ids.count
  end

  test "returns created true for new days" do
    service = Days::DayOpeningService.new(user: @user, date: @date)
    result = service.call

    assert result[:created]
    assert_not result[:reopened]
  end

  test "returns reopened true for reopened days" do
    # Descendant created automatically by after_create callback
    day = @user.days.create!(date: @date, state: :closed)

    service = Days::DayOpeningService.new(user: @user, date: @date)
    result = service.call

    assert_not result[:created]
    assert result[:reopened]
  end

  test "handles date parsing from String" do
    service = Days::DayOpeningService.new(user: @user, date: "2025-12-31")
    result = service.call

    assert result[:success]
    assert_equal Date.parse("2025-12-31"), result[:day].date
  end

  test "CRITICAL: never duplicates permanent sections on new day creation" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    service = Days::DayOpeningService.new(user: @user, date: @date)
    result = service.call

    day = result[:day]
    active_item_ids = day.descendant.extract_active_item_ids
    work_sections = Item.where(id: active_item_ids, title: "Work", item_type: :section)

    # Should have exactly ONE Work section
    assert_equal 1, work_sections.count
  end

  test "CRITICAL: case-insensitive title matching prevents duplicates" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    # Manually create a section with different case
    # Descendant created automatically by after_create callback
    day = @user.days.create!(date: @date, state: :open, skip_permanent_sections_callback: true)

    # Create "work" (lowercase) manually
    existing_section = @user.items.create!(title: "work", item_type: :section, state: :todo)
    day.descendant.add_active_item(existing_section.id)
    day.descendant.save!

    # Now add permanent sections (which has "Work")
    result = Days::AddPermanentSectionsService.new(day: day, user: @user).call

    assert result[:success]
    assert_equal 0, result[:sections_added]

    # Should still have only ONE section total
    day.reload
    active_item_ids = day.descendant.extract_active_item_ids
    assert_equal 1, active_item_ids.count
  end

  test "CRITICAL: creates sections in user permanent_sections order" do
    @user.permanent_sections = [ "Zebra", "Apple", "Banana" ]
    @user.save!

    service = Days::DayOpeningService.new(user: @user, date: @date)
    result = service.call

    day = result[:day]
    active_item_ids = day.descendant.extract_active_item_ids
    items = Item.where(id: active_item_ids).index_by(&:id)

    # Order should match permanent_sections order
    ordered_titles = active_item_ids.map { |id| items[id].title }
    assert_equal [ "Zebra", "Apple", "Banana" ], ordered_titles
  end

  # Transaction rollback is handled by Rails ActiveRecord::Base.transaction
  # and is well-tested by Rails itself. We rely on this built-in behavior.

  test "handles Date object input" do
    date_obj = Date.new(2025, 12, 25)
    service = Days::DayOpeningService.new(user: @user, date: date_obj)
    result = service.call

    assert result[:success]
    assert_equal date_obj, result[:day].date
  end

  test "does not skip permanent sections callback when creating day" do
    @user.permanent_sections = [ "Work" ]
    @user.save!

    service = Days::DayOpeningService.new(user: @user, date: @date)
    result = service.call

    # Permanent sections should be created
    day = result[:day]
    active_item_ids = day.descendant.extract_active_item_ids
    assert_equal 1, active_item_ids.count
  end
end
