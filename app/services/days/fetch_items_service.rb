# frozen_string_literal: true

class Days::FetchItemsService
  # Service for recursively fetching all items from a day with nested items
  # Also fetches lists (as leaf nodes, no recursion)
  # Returns:
  #   all_items: Flat array of all items at all nesting levels
  #   item_descendant_map: Maps item IDs to their descendant IDs (for tree building)
  #   active_items: Top-level active items (filtered from all_items)
  #   inactive_items: Top-level inactive items (filtered from all_items)
  #   all_lists: Flat array of all lists linked to the day
  #   active_lists: Top-level active lists
  #   inactive_lists: Top-level inactive lists

  attr_reader :day

  def initialize(day:)
    @day = day
    @all_items = []
    @item_descendant_map = {}
    @all_lists = []
  end

  def call
    return default_result unless day&.descendant

    # Start traversal from day's descendant for items
    traverse_descendant(day.descendant)

    # Fetch lists from day's descendant (lists are leaf nodes, no recursion)
    fetch_lists(day.descendant)

    # Filter top-level items from all_items (extract IDs from tuples)
    top_level_active_item_ids = day.descendant.extract_active_item_ids
    top_level_inactive_item_ids = day.descendant.extract_inactive_item_ids

    active_items = @all_items.select { |item| top_level_active_item_ids.include?(item.id) }
    inactive_items = @all_items.select { |item| top_level_inactive_item_ids.include?(item.id) }

    # Filter top-level lists
    top_level_active_list_ids = day.descendant.extract_active_ids_by_type("List")
    top_level_inactive_list_ids = day.descendant.extract_inactive_ids_by_type("List")

    active_lists = @all_lists.select { |list| top_level_active_list_ids.include?(list.id) }
    inactive_lists = @all_lists.select { |list| top_level_inactive_list_ids.include?(list.id) }

    {
      all_items: @all_items,
      item_descendant_map: @item_descendant_map,
      active_items: active_items,
      inactive_items: inactive_items,
      all_lists: @all_lists,
      active_lists: active_lists,
      inactive_lists: inactive_lists
    }
  end

  private

  def default_result
    {
      all_items: [],
      item_descendant_map: {},
      active_items: [],
      inactive_items: [],
      all_lists: [],
      active_lists: [],
      inactive_lists: []
    }
  end

  def fetch_lists(descendant)
    # Extract list IDs from descendant (no recursion - lists are leaf nodes)
    all_list_ids = descendant.extract_active_ids_by_type("List") +
                   descendant.extract_inactive_ids_by_type("List")
    return if all_list_ids.empty?

    # Fetch all lists with their descendants
    @all_lists = List.where(id: all_list_ids).includes(:descendant).to_a
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
