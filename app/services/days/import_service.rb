# frozen_string_literal: true

class Days::ImportService
  # Service for importing todo items from latest importable closed day
  # Returns: { imported_count: Integer, target_day: Day }
  #
  # - Uses FindLatestImportableDayService to find latest closed day globally
  # - Validates that latest importable day is before current date
  # - Only imports items with state: "todo" (not completed/dropped/deferred)
  # - Recursively traverses item tree, only processing active_items (not inactive_items)
  # - Order preservation: Maps over active_items array to ensure exact order
  # - Creates items in order: parent item added first, then recursively processes children
  # - Creates target day and descendant if they don't exist
  # - Updates both source and target days with import relationships
  # - Handles empty imports (no todo items) by still marking import relationship

  attr_reader :user, :target_date, :migration_settings

  def initialize(user:, target_date:, migration_settings: nil)
    @user = user
    @target_date = target_date.is_a?(Date) ? target_date : Date.parse(target_date.to_s)
    @migration_settings = migration_settings || user.day_migration_settings || MigrationOptions.defaults
    @item_mapping = {} # Maps old item IDs to new item IDs
    @section_mapping = {} # Maps old section IDs to existing target day section IDs
    @items_to_import = [] # Items to import in order
    @descendants_to_create = [] # Descendants to create after items
    @imported_count = 0
  end

  def call
    ActiveRecord::Base.transaction do
      # Step 1: Find latest importable day (from days before target_date)
      source_day = Days::FindLatestImportableDayService.new(user: user, current_date: target_date).call

      # Step 2: Validate import conditions
      validation = Days::ValidateImportConditionsService.new(
        user: user,
        source_day: source_day,
        target_date: target_date
      ).call

      unless validation[:valid]
        raise StandardError, validation[:error_message]
      end

      # Step 3: Find or create target day
      target_day = find_or_create_target_day

      # Step 4: Map permanent sections from source to target
      map_permanent_sections(source_day, target_day)

      # Step 5: Collect all todo items to import (recursively, only from active_items)
      collect_items_to_import(source_day.descendant)

      # Step 6: Create new items on target day maintaining order
      create_imported_items(target_day)

      # Step 7: Create descendants for items that had nested items
      create_item_descendants

      # Step 8: Update import relationships
      target_day.import_from!(source_day)

      { imported_count: @imported_count, target_day: target_day }
    end
  end

  private

  def should_import_item?(item, parent_item: nil)
    # Always import completable items (todos)
    return true if item.completable?

    # Check section type against migration settings
    if parent_item
      # This is a nested item, check items.sections setting
      return false if item.section? && !migration_settings.dig("items", "sections")
    else
      # This is a top-level item, check active_item_sections setting
      return false if item.section? && !migration_settings.dig("active_item_sections")
    end

    # For reusable and trackable items, import them by default
    true
  end

  def map_permanent_sections(source_day, target_day)
    # Find all permanent sections on source day
    return unless source_day.descendant

    source_section_ids = source_day.descendant.extract_active_item_ids
    source_sections = Item.sections.where(id: source_section_ids).select { |s| s.extra_data&.dig("permanent_section") }

    source_sections.each do |source_section|
      # Find matching section on target day by title
      target_section = find_section_on_day(target_day, source_section.title)

      if target_section
        # Map old section ID to existing target section ID
        @section_mapping[source_section.id] = target_section.id
      end
    end
  end

  def find_section_on_day(day, section_title)
    return nil unless day.descendant

    section_ids = day.descendant.extract_active_item_ids
    sections = Item.sections.where(id: section_ids, title: section_title)
    sections.first
  end

  def find_or_create_target_day
    day = user.days.find_by(date: target_date)

    if day
      # Ensure descendant exists
      unless day.descendant
        Descendant.create!(
          descendable: day,
          active_items: [],
          inactive_items: []
        )
      end
      return day
    end

    # Create new day with permanent sections
    Days::OpenDayService.new(user: user, date: target_date).call
  end

  def collect_items_to_import(descendant, parent_item_id: nil, parent_item: nil)
    return unless descendant

    # Only process active_items (not inactive_items) - extract IDs from tuples
    active_item_ids = descendant.extract_active_item_ids
    return if active_item_ids.empty?

    # Fetch items and create map for lookup
    items = Item.where(id: active_item_ids).includes(:descendant).index_by(&:id)

    # Order items by mapping over active_items array - this is the source of truth for order
    ordered_items = active_item_ids.map { |id| items[id] }.compact

    # Process items in active_items order: parent before children
    ordered_items.each do |item|
      # Only import TODO items
      next unless item.state == "todo"

      # Check if item should be imported based on migration settings
      next unless should_import_item?(item, parent_item: parent_item)

      # Add to items_to_import array (maintains order)
      @items_to_import << {
        item: item,
        parent_item_id: parent_item_id
      }
      @imported_count += 1

      # Recursively process children if this item has a descendant with active items
      if item.descendant && item.descendant.extract_active_item_ids.any?
        collect_items_to_import(item.descendant, parent_item_id: item.id, parent_item: item)
      end
    end
  end

  def create_imported_items(target_day)
    # Process items in the exact order they appear in items_to_import
    @items_to_import.each do |item_data|
      original_item = item_data[:item]
      parent_item_id = item_data[:parent_item_id]

      # Check if this is a permanent section that already exists on target day
      if original_item.section? && original_item.extra_data&.dig("permanent_section")
        existing_section_id = @section_mapping[original_item.id]
        if existing_section_id
          # Don't create a new section, use the existing one
          @item_mapping[original_item.id] = existing_section_id

          # Track if this section needs its descendant updated with nested items
          if original_item.descendant && original_item.descendant.extract_active_item_ids.any?
            existing_section = Item.find(existing_section_id)
            @descendants_to_create << {
              original_item: original_item,
              new_item: existing_section
            }
          end

          # Decrement count since we're not actually creating this item
          @imported_count -= 1

          # Skip creating this item
          next
        end
      end

      # Create new item with same properties
      new_item = user.items.create!(
        title: original_item.title,
        item_type: original_item.item_type,
        state: :todo,
        extra_data: original_item.extra_data,
        source_item_id: original_item.id
      )

      # Map old ID to new ID
      @item_mapping[original_item.id] = new_item.id

      # Track if this item needs a descendant created
      if original_item.descendant && original_item.descendant.extract_active_item_ids.any?
        @descendants_to_create << {
          original_item: original_item,
          new_item: new_item
        }
      end

      # Add to parent (either day or parent item)
      if parent_item_id
        # This is a nested item - will be added to parent's descendant later
        # (descendants created in next step)
      else
        # This is a top-level item - add to day's descendant
        target_day.descendant.add_active_item(new_item.id)
        target_day.descendant.save!
      end
    end
  end

  def create_item_descendants
    @descendants_to_create.each do |desc_data|
      original_item = desc_data[:original_item]
      new_item = desc_data[:new_item]

      # Get original nested item IDs (only active_items) - extract from tuples
      original_nested_ids = original_item.descendant.extract_active_item_ids

      # Map to new item IDs, maintaining order from active_items array
      new_nested_ids = original_nested_ids.map { |old_id| @item_mapping[old_id] }.compact

      # Check if descendant already exists (sections auto-create descendants)
      # If it exists, update it; otherwise create it
      descendant = new_item.descendant
      if descendant
        # APPEND to existing active_items (for permanent sections that already have items)
        # Add new items one by one using the add_active_item method
        new_nested_ids.each do |item_id|
          descendant.add_active_item(item_id)
        end
        descendant.save!
      else
        # Create new descendant with tuple format
        new_active_tuples = new_nested_ids.map { |id| { "Item" => id } }
        Descendant.create!(
          descendable: new_item,
          active_items: new_active_tuples,
          inactive_items: []
        )
      end
    end
  end
end
