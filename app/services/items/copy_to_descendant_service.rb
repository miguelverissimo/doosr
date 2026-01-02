# frozen_string_literal: true

class Items::CopyToDescendantService
  # Service for copying an item to a target descendant
  # Creates a new item with all attributes from source and adds it to the target descendant
  # Recursively copies all descendant items based on copy_settings
  #
  # Returns: { success: Boolean, new_item: Item }

  attr_reader :source_item, :target_descendant, :user, :copy_settings

  def initialize(source_item:, target_descendant:, user:, copy_settings: nil)
    @source_item = source_item
    @target_descendant = target_descendant
    @user = user
    @copy_settings = copy_settings || default_copy_settings
  end

  def call
    ActiveRecord::Base.transaction do
      # Create new item copying all relevant attributes
      new_item = create_new_item

      # Add to appropriate array based on state
      add_to_target_descendant(new_item)

      target_descendant.save!

      # Recursively copy descendants if source item has any
      copy_descendants(new_item) if source_item.descendant.present?

      { success: true, new_item: new_item }
    end
  rescue StandardError => e
    Rails.logger.error "Copy item failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { success: false, error: e.message }
  end

  private

  def default_copy_settings
    user.day_migration_settings&.dig("items") || MigrationOptions.defaults["items"]
  end

  def create_new_item
    # CRITICAL: Never copy the permanent_section flag to prevent duplicates
    # Permanent sections should always be created by DayOpeningService, not by copying
    extra_data_to_copy = source_item.extra_data&.dup || {}
    extra_data_to_copy.delete("permanent_section") if extra_data_to_copy.is_a?(Hash)

    user.items.create!(
      title: source_item.title,
      item_type: source_item.item_type,
      state: source_item.state,
      extra_data: extra_data_to_copy.presence,
      source_item_id: source_item.id,
      deferred_at: source_item.deferred_at,
      deferred_to: source_item.deferred_to,
      recurrence_rule: source_item.recurrence_rule
    )
  end

  def add_to_target_descendant(new_item)
    if source_item.state == "todo"
      target_descendant.add_active_item(new_item.id)
    else
      target_descendant.add_inactive_item(new_item.id)
    end
  end

  def copy_descendants(new_item)
    source_descendant = source_item.descendant
    return unless source_descendant

    # For sections with no active items in tree: create empty descendant if setting enabled, but don't copy children
    if source_item.item_type == "section" && !section_has_active_items_in_tree?(source_item)
      if copy_settings.dig("sections_with_no_active_items") != false
        new_item.descendant || new_item.create_descendant!
      end
      return
    end

    # Get ONLY active items from source descendant (inactive items NEVER get migrated)
    active_item_ids = source_descendant.extract_active_item_ids
    source_child_items = Item.where(id: active_item_ids)

    # Filter items based on copy_settings (only copy sections that have active items in their tree)
    items_to_copy = source_child_items.select { |item| should_copy_item_for_migration?(item) }

    return if items_to_copy.empty?

    # Ensure new_item has a descendant to hold the copied items
    new_item.descendant || new_item.create_descendant!

    # Recursively copy each child item
    items_to_copy.each do |child_item|
      Items::CopyToDescendantService.new(
        source_item: child_item,
        target_descendant: new_item.descendant,
        user: user,
        copy_settings: copy_settings
      ).call
    end

    # Copy notes if enabled
    copy_notes(source_descendant, new_item.descendant) if should_copy_notes?
  end

  def should_copy_item_for_migration?(item)
    # Used when filtering child items for copying
    # Note: We only get active items from descendant, but need to filter by state too

    # CRITICAL: NEVER copy permanent sections - they should already exist in target day
    # Permanent sections are ALWAYS at day root level and should never be nested
    # If we encounter one nested, skip it to prevent duplicates
    if item.item_type == "section" && item.extra_data&.dig("permanent_section")
      return false
    end

    # CRITICAL: Completable items ONLY get copied if they are in 'todo' state
    # NEVER copy completable items that are done, dropped, or deferred
    if item.item_type == "completable"
      return item.state == "todo"
    end

    # For non-section items (reusable, trackable), check state
    unless item.item_type == "section"
      # Only copy if in todo state
      return item.state == "todo"
    end

    # For sections without any descendants, always copy (just a header/organizational element)
    return true unless item.descendant.present?

    # For sections with empty descendants (no children at all), always copy (just a header)
    active_item_ids = item.descendant.extract_active_item_ids
    return true if active_item_ids.empty?

    # For sections with children:
    # - If sections_with_no_active_items is true: always copy the section (will be created as empty if no active todo items)
    # - If sections_with_no_active_items is false: only copy if section has todo items in its tree
    if copy_settings.dig("sections_with_no_active_items") != false
      true  # Copy all sections when setting is true
    else
      section_has_active_items_in_tree?(item)  # Only copy sections with todo items when setting is false
    end
  end

  def section_has_active_items_in_tree?(section)
    return false unless section.descendant.present?

    active_item_ids = section.descendant.extract_active_item_ids
    return false if active_item_ids.empty?

    active_items = Item.where(id: active_item_ids)

    # Check if any active item is not a section AND is in 'todo' state (i.e., an actual task to migrate)
    # CRITICAL: Only items in 'todo' state count as active items for migration
    non_section_items = active_items.where.not(item_type: :section).where(state: :todo)
    return true if non_section_items.any?

    # If all active items are sections, recursively check them
    section_items = active_items.where(item_type: :section)
    section_items.any? { |child_section| section_has_active_items_in_tree?(child_section) }
  end

  def should_copy_notes?
    copy_settings.dig("notes") != false
  end

  def copy_notes(source_descendant, target_descendant)
    # Placeholder for copying notes
    # Notes implementation will be added later with different logic
  end
end
