# frozen_string_literal: true

class Items::DeferService
  # Service for deferring an item to a target date.
  #
  # This service:
  # - Validates item is in 'todo' state
  # - Creates target day with descendant if needed
  # - ALWAYS ensures permanent sections exist on target day
  # - Finds which permanent section (if any) the source item belongs to
  # - Copies item to the SAME permanent section on target day (or day root if not in a section)
  # - Sets source item: state=deferred, deferred_at=now, deferred_to=target_date
  # - Moves source item from active_items to inactive_items in its descendant
  #
  # Returns: { success: Boolean, new_item: Item, nested_items_count: Integer, error: String }

  attr_reader :source_item, :target_date, :user

  def initialize(source_item:, target_date:, user:)
    @source_item = source_item
    @target_date = target_date.is_a?(Date) ? target_date : Date.parse(target_date.to_s)
    @user = user
  end

  def call
    # Validate item can be deferred
    return validation_error unless can_defer?

    # Count nested todo items for confirmation
    nested_count = count_nested_todo_items

    ActiveRecord::Base.transaction do
      # Find or create target day with descendant
      target_day = find_or_create_target_day

      # ALWAYS ensure permanent sections exist on target day
      ensure_permanent_sections(target_day)

      # Find which permanent section (if any) the source item belongs to
      source_permanent_section = source_item.find_permanent_section

      # Determine target descendant (either permanent section's descendant or day's descendant)
      target_descendant = if source_permanent_section
        find_or_create_matching_permanent_section(target_day, source_permanent_section)
      else
        target_day.descendant
      end

      # Copy item to target descendant using CopyToDescendantService
      result = Items::CopyToDescendantService.new(
        source_item: source_item,
        target_descendant: target_descendant,
        user: user,
        copy_settings: user.day_migration_settings&.dig("items") || MigrationOptions.defaults["items"]
      ).call

      return result unless result[:success]

      new_item = result[:new_item]

      # Update source item: mark as deferred and set timestamps
      # Note: Sections cannot have completion states, so keep them as :todo
      if source_item.section?
        source_item.update!(
          deferred_at: Time.current,
          deferred_to: target_date.to_time
        )
      else
        source_item.update!(
          state: :deferred,
          deferred_at: Time.current,
          deferred_to: target_date.to_time
        )
      end

      # Move source item from active to inactive in its descendant
      move_source_to_inactive

      {
        success: true,
        new_item: new_item,
        nested_items_count: nested_count
      }
    end
  rescue StandardError => e
    Rails.logger.error "Defer item failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { success: false, error: e.message }
  end

  private

  def can_defer?
    # Only items in 'todo' state can be deferred
    source_item.todo?
  end

  def validation_error
    {
      success: false,
      error: "Only items in 'todo' state can be deferred. Current state: #{source_item.state}"
    }
  end

  def count_nested_todo_items
    return 0 unless source_item.descendant&.active_items&.any?

    active_item_ids = source_item.descendant.extract_active_item_ids
    active_items = Item.where(id: active_item_ids)

    # Count only todo items recursively
    count_todo_items_recursive(active_items)
  end

  def count_todo_items_recursive(items)
    count = 0
    items.each do |item|
      count += 1 if item.todo?

      if item.descendant&.active_items&.any?
        nested_ids = item.descendant.extract_active_item_ids
        nested_items = Item.where(id: nested_ids)
        count += count_todo_items_recursive(nested_items)
      end
    end
    count
  end

  def find_or_create_target_day
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

  def move_source_to_inactive
    # Find which descendant contains this item
    containing_descendant = Descendant.containing_item(source_item.id)
    return unless containing_descendant

    # Only move if in active items
    return unless containing_descendant.active_item?(source_item.id)

    # Move from active to inactive
    containing_descendant.remove_active_item(source_item.id)
    containing_descendant.add_inactive_item(source_item.id)
    containing_descendant.save!
  end
end
