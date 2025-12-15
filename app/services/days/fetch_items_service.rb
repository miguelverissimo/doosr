# frozen_string_literal: true

class Days::FetchItemsService
  # Service for recursively fetching all items from a day with nested items
  # Returns:
  #   all_items: Flat array of all items at all nesting levels
  #   item_descendant_map: Maps item IDs to their descendant IDs (for tree building)
  #   active_items: Top-level active items (filtered from all_items)
  #   inactive_items: Top-level inactive items (filtered from all_items)

  attr_reader :day

  def initialize(day:)
    @day = day
    @all_items = []
    @item_descendant_map = {}
  end

  def call
    return default_result unless day&.descendant

    # Start traversal from day's descendant
    traverse_descendant(day.descendant)

    # Filter top-level items from all_items (extract IDs from tuples)
    top_level_active_item_ids = day.descendant.extract_active_item_ids
    top_level_inactive_item_ids = day.descendant.extract_inactive_item_ids

    active_items = @all_items.select { |item| top_level_active_item_ids.include?(item.id) }
    inactive_items = @all_items.select { |item| top_level_inactive_item_ids.include?(item.id) }

    {
      all_items: @all_items,
      item_descendant_map: @item_descendant_map,
      active_items: active_items,
      inactive_items: inactive_items
    }
  end

  private

  def default_result
    {
      all_items: [],
      item_descendant_map: {},
      active_items: [],
      inactive_items: []
    }
  end

  def traverse_descendant(descendant)
    # Get all item IDs from this descendant (extract from tuples)
    all_item_ids = descendant.extract_active_item_ids + descendant.extract_inactive_item_ids
    return if all_item_ids.empty?

    # Fetch all items with their descendants
    items = Item.where(id: all_item_ids).includes(:descendant).index_by(&:id)

    # Process items in order they appear in descendant arrays
    all_item_ids.each do |item_id|
      item = items[item_id]
      next unless item

      # Add item to all_items
      @all_items << item

      # Check if this item owns a descendant (has nested items)
      if item.descendant
        # Map this item to its descendant
        @item_descendant_map[item.id] = item.descendant.id

        # Recursively traverse this item's descendant
        traverse_descendant(item.descendant)
      end
    end
  end
end
