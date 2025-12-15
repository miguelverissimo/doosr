# frozen_string_literal: true

class Days::OpenDayService
  # Service for creating a new day with permanent sections initialization
  # Returns: Day
  #
  # - Creates day with open state (if it does not already exist)
  # - Creates and links day-level descendant
  # - Initializes all permanent sections from user preferences exactly once for that day
  # - Prevents creating if day already exists (raises error)

  attr_reader :user, :date

  def initialize(user:, date:)
    @user = user
    @date = date.is_a?(Date) ? date : Date.parse(date.to_s)
  end

  def call
    ActiveRecord::Base.transaction do
      # Check if day already exists
      existing_day = user.days.find_by(date: date)
      if existing_day
        raise ActiveRecord::RecordNotUnique, "Day already exists for this date"
      end

      # Create day with open state
      day = user.days.create!(date: date, state: :open)

      # Ensure descendant exists (should be auto-created by callback, but ensure)
      unless day.descendant
        Descendant.create!(
          descendable: day,
          active_items: [],
          inactive_items: []
        )
      end

      # Initialize permanent sections from user preferences
      initialize_permanent_sections(day)

      day
    end
  end

  private

  def initialize_permanent_sections(day)
    permanent_sections = user.permanent_sections || []
    return if permanent_sections.empty?

    permanent_sections.each do |section_name|
      # Check if section already exists on day (by title)
      existing_section = find_section_on_day(day, section_name)
      next if existing_section

      # Create section item
      section = user.items.create!(
        title: section_name,
        item_type: :section,
        state: :todo,
        extra_data: { permanent_section: true }
      )

      # Add section to day's active items
      day.descendant.add_active_item(section.id)
      day.descendant.save!
    end
  end

  def find_section_on_day(day, section_title)
    return nil unless day.descendant

    section_ids = day.descendant.extract_active_item_ids
    sections = Item.sections.where(id: section_ids, title: section_title)
    sections.first
  end
end
