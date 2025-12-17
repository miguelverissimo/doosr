# frozen_string_literal: true

module Items
  # Service for scheduling the next occurrence of a recurring item.
  #
  # This service:
  # - Calculates the next occurrence date based on recurrence_rule
  # - Creates target day with descendant if needed
  # - Ensures permanent sections exist on target day
  # - Finds which permanent section (if any) the completed item belongs to
  # - Creates new item in the SAME permanent section on target day (or day root if not in a section)
  # - Sets recurring_next_item_id on the completed item
  #
  # Returns: { success: Boolean, new_item: Item, error: String }
  class ScheduleNextOccurrenceService
    attr_reader :completed_item, :user

    def initialize(completed_item:, user:)
      @completed_item = completed_item
      @user = user
    end

    def call
      # Check if item has recurrence
      return no_recurrence_error unless completed_item.has_recurrence?

      # Calculate next occurrence date
      next_date = calculate_next_date
      return calculation_error unless next_date

      ActiveRecord::Base.transaction do
        # Find or create target day with descendant
        target_day = find_or_create_target_day(next_date)

        # ALWAYS ensure permanent sections exist on target day
        ensure_permanent_sections(target_day)

        # Find which permanent section (if any) the completed item belongs to
        source_permanent_section = completed_item.find_permanent_section

        # Determine target descendant (either permanent section's descendant or day's descendant)
        target_descendant = if source_permanent_section
          find_or_create_matching_permanent_section(target_day, source_permanent_section)
        else
          target_day.descendant
        end

        # Create new todo item with same properties
        new_item = create_new_item(target_descendant)

        # Link completed item to new item
        completed_item.update!(recurring_next_item_id: new_item.id)

        {
          success: true,
          new_item: new_item
        }
      end
    rescue StandardError => e
      Rails.logger.error "Schedule next occurrence failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { success: false, error: e.message }
    end

    private

    def calculate_next_date
      calculator = RecurrenceCalculator.new(
        recurrence_rule: completed_item.recurrence_rule,
        from_date: Date.today
      )
      calculator.call
    end

    def no_recurrence_error
      { success: false, error: "Item does not have a recurrence rule" }
    end

    def calculation_error
      { success: false, error: "Failed to calculate next occurrence date" }
    end

    def find_or_create_target_day(target_date)
      day = user.days.find_by(date: target_date)

      if day
        # Ensure descendant exists
        day.descendant || day.create_descendant!(active_items: [], inactive_items: [])
        return day
      end

      # Create new day with descendant
      day = user.days.create!(date: target_date, state: :open)

      # Ensure descendant exists
      day.descendant || day.create_descendant!(active_items: [], inactive_items: [])

      day
    end

    def ensure_permanent_sections(day)
      # ALWAYS ensure permanent sections exist on the target day
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

        # Ensure section has a descendant
        section.descendant || section.create_descendant!(active_items: [], inactive_items: [])

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

    def find_or_create_matching_permanent_section(day, source_section)
      # Find the matching permanent section on the target day
      matching_section = find_section_on_day(day, source_section.title)

      if matching_section
        # Ensure it has a descendant
        matching_section.descendant || matching_section.create_descendant!(active_items: [], inactive_items: [])
        return matching_section.descendant
      end

      # This should not happen since we ensured permanent sections above
      # but handle it gracefully by creating the section
      new_section = user.items.create!(
        title: source_section.title,
        item_type: :section,
        state: :todo,
        extra_data: { permanent_section: true }
      )

      # Ensure section has a descendant
      new_section.create_descendant!(active_items: [], inactive_items: [])

      # Add section to day's active items
      day.descendant.add_active_item(new_section.id)
      day.descendant.save!

      new_section.descendant
    end

    def create_new_item(target_descendant)
      # Create new item with same properties
      new_item = user.items.create!(
        title: completed_item.title,
        item_type: completed_item.item_type,
        state: :todo,
        recurrence_rule: completed_item.recurrence_rule,
        extra_data: completed_item.extra_data
      )

      # Add to target descendant's active items
      target_descendant.add_active_item(new_item.id)
      target_descendant.save!

      new_item
    end
  end
end
