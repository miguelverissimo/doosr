# frozen_string_literal: true

class Items::DeferService
  # Service for deferring items to a target date.
  # This service:
  # - Recursively collects item and all nested todo items
  # - Tracks section information for each item
  # - Creates target day and descendant if needed
  # - Creates or finds permanent sections on target day
  # - Creates new items maintaining hierarchy
  # - Sets source_item_id, deferred_at, deferred_to
  # - Moves original items from activeItems to inactiveItems
  #
  # This service is generic and can also be used for copying items to a target day.
  attr_reader :source_item, :target_date, :user, :deferred_items_count

  def initialize(source_item:, target_date:, user:)
  @source_item = source_item
  @target_date = target_date.is_a?(Date) ? target_date : Date.parse(target_date.to_s)
  @user = user
  @deferred_items_count = 0
  @item_mapping = {} # Maps old item IDs to new item IDs
  @section_mapping = {} # Maps section titles to section IDs on target day
  @items_to_create = [] # Items to create (first pass)
  @descendants_to_link = [] # Descendants to link (second pass)
  end

  def call
  ActiveRecord::Base.transaction do
    # Step 1: Find or create target day
    target_day = find_or_create_target_day

    # Step 2: Collect all items to defer (recursively)
    collect_items_to_defer(source_item, parent_section: nil)

    # Step 3: Create permanent sections on target day if needed
    create_permanent_sections(target_day)

    # Step 4: Create new items on target day (first pass)
    create_new_items(target_day)

    # Step 5: Link items and create descendants (second pass)
    link_descendants

    # Step 6: Mark original items as deferred and move to inactive
    mark_original_items_as_deferred

    # Return deferred count
    @deferred_items_count
  end
  end

  private

  def find_or_create_target_day
    day = user.days.find_or_create_by!(date: target_date)

    # Ensure descendant exists
    unless day.descendant
      Descendant.create!(
        descendable: day,
        active_items: [],
        inactive_items: []
      )
    end

    day
  end

  def collect_items_to_defer(item, parent_section:)
    # Track this item
    item_data = {
      item: item,
      parent_section: parent_section
    }

    # Determine if this is a permanent section
    current_section = if item.section? && item.extra_data['permanent_section']
      item
    else
      parent_section
    end

    # Only defer TODO items (skip done, dropped, already deferred)
    if item.todo?
      @items_to_create << item_data
      @deferred_items_count += 1
    end

    # Recursively collect nested items (only from TODO items)
    if item.todo? && item.descendant&.active_items&.any?
      nested_items = Item.where(id: item.descendant.active_items).includes(:descendant)
      nested_items.each do |nested_item|
        collect_items_to_defer(nested_item, parent_section: current_section)
      end
    end
  end

  def create_permanent_sections(target_day)
    # Find all permanent sections we need to create/find
    permanent_sections = @items_to_create
      .select { |data| data[:item].section? && data[:item].extra_data['permanent_section'] }
      .map { |data| data[:item] }

    permanent_sections.each do |section|
      # Check if section already exists on target day
      existing_section = find_section_on_day(target_day, section.title)

      if existing_section
        # Section exists, map it
        @section_mapping[section.title] = existing_section.id
      else
        # Create new section
        new_section = user.items.create!(
          title: section.title,
          item_type: :section,
          state: :todo,
          extra_data: section.extra_data
        )

        # Add section to day's active items
        target_day.descendant.active_items = (target_day.descendant.active_items + [new_section.id]).uniq
        target_day.descendant.save!

        @section_mapping[section.title] = new_section.id
      end
    end
  end

  def find_section_on_day(day, section_title)
    return nil unless day.descendant

    section_ids = day.descendant.active_items
    sections = Item.sections.where(id: section_ids, title: section_title)
    sections.first
  end

  def create_new_items(target_day)
    @items_to_create.each do |item_data|
      original_item = item_data[:item]
      parent_section = item_data[:parent_section]

      # Create new item with same properties
      new_item = user.items.create!(
        title: original_item.title,
        item_type: original_item.item_type,
        state: :todo,
        extra_data: original_item.extra_data,
        source_item: original_item
      )

      # Map old ID to new ID
      @item_mapping[original_item.id] = new_item.id

      # Track if this item needs descendants linked later
      if original_item.descendant&.active_items&.any?
        @descendants_to_link << {
          original_item: original_item,
          new_item: new_item
        }
      end

      # Add item to appropriate location
      if parent_section && parent_section.extra_data['permanent_section']
        # Add to permanent section's descendant
        section_id = @section_mapping[parent_section.title]
        if section_id
          section = Item.find(section_id)
          section.descendant ||= Descendant.create!(
            descendable: section,
            active_items: [],
            inactive_items: []
          )
          section.descendant.active_items = (section.descendant.active_items + [new_item.id]).uniq
          section.descendant.save!
        end
      else
        # Add to day's active items
        target_day.descendant.active_items = (target_day.descendant.active_items + [new_item.id]).uniq
        target_day.descendant.save!
      end
    end
  end

  def link_descendants
    @descendants_to_link.each do |link_data|
      original_item = link_data[:original_item]
      new_item = link_data[:new_item]

      # Get the new IDs of nested items
      original_nested_ids = original_item.descendant.active_items
      new_nested_ids = original_nested_ids.map { |old_id| @item_mapping[old_id] }.compact

      # Create descendant for new item
      Descendant.create!(
        descendable: new_item,
        active_items: new_nested_ids,
        inactive_items: []
      )
    end
  end

  def mark_original_items_as_deferred
    @items_to_create.each do |item_data|
      original_item = item_data[:item]

      # Mark as deferred
      original_item.update!(
        state: :deferred,
        deferred_at: Time.current,
        deferred_to: target_date.to_time
      )

      # Move from active to inactive in parent descendant
      move_to_inactive(original_item)
    end
  end

  def move_to_inactive(item)
    # Find which descendant contains this item
    descendant = Descendant.where(
      "active_items @> ?", [item.id].to_json
    ).first

    return unless descendant

    # Remove from active_items
    descendant.active_items = descendant.active_items.reject { |id| id == item.id }

    # Add to inactive_items (deduplicate)
    descendant.inactive_items = (descendant.inactive_items + [item.id]).uniq

    descendant.save!
  end
end
