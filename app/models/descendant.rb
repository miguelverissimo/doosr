# frozen_string_literal: true

# Descendant is a polymorphic model that stores ordered lists of record tuples
# for any parent model (Day, List, or Item).
#
# It maintains two separate ordered arrays:
# - active_items: Array of record tuples in display order (e.g., [{"Item" => 1}, {"Link" => 5}])
# - inactive_items: Array of record tuples in display order
#
# Each tuple is a hash with a single key-value pair:
# - Key: Record type (string) - "Item", "Link", "Note"
# - Value: Record ID (integer)
#
# Example usage:
#   day = Day.find(1)
#   day.descendant.add_active_record("Item", 123)
#   day.descendant.add_active_record("Link", 456)
#   day.descendant.active_items # => [{"Item" => 123}, {"Link" => 456}]
#   day.descendant.save
#
class Descendant < ApplicationRecord
  # Polymorphic association - can belong to Day, List, or Item
  belongs_to :descendable, polymorphic: true

  # Validations
  validate :arrays_contain_tuples

  # Ensure active_items and inactive_items are always arrays
  after_initialize :ensure_arrays

  # ============================================================================
  # Tuple Helper Methods
  # ============================================================================

  # Build a tuple from type and id
  # @param type [String] The record type (e.g., "Item", "Link")
  # @param id [Integer] The record ID
  # @return [Hash] The tuple (e.g., {"Item" => 123})
  def build_tuple(type, id)
    { type => id }
  end

  # Parse a tuple into type and id
  # @param tuple [Hash] The tuple (e.g., {"Item" => 123})
  # @return [Array] [type, id] (e.g., ["Item", 123])
  def parse_tuple(tuple)
    tuple.first
  end

  # Extract all IDs of a specific type from an array
  # @param array [Array<Hash>] Array of tuples
  # @param type [String] The record type to filter by
  # @return [Array<Integer>] Array of IDs
  def extract_ids_by_type(array, type)
    array.select { |tuple| tuple.key?(type) }.map { |tuple| tuple[type] }
  end

  # Extract all IDs from active_items by type
  # @param type [String] The record type (e.g., "Item")
  # @return [Array<Integer>] Array of IDs
  def extract_active_ids_by_type(type)
    extract_ids_by_type(active_items, type)
  end

  # Extract all IDs from inactive_items by type
  # @param type [String] The record type (e.g., "Item")
  # @return [Array<Integer>] Array of IDs
  def extract_inactive_ids_by_type(type)
    extract_ids_by_type(inactive_items, type)
  end

  # Extract all item IDs from active_items (convenience method)
  # @return [Array<Integer>] Array of item IDs
  def extract_active_item_ids
    extract_active_ids_by_type("Item")
  end

  # Extract all item IDs from inactive_items (convenience method)
  # @return [Array<Integer>] Array of item IDs
  def extract_inactive_item_ids
    extract_inactive_ids_by_type("Item")
  end

  # ============================================================================
  # Array Manipulation Methods
  # ============================================================================

  # Add a record to active_items (at the end)
  # @param type [String] The record type (e.g., "Item", "Link")
  # @param id [Integer] The record ID
  def add_active_record(type, id)
    tuple = build_tuple(type, id)
    return if active_items.include?(tuple)
    self.active_items = active_items + [ tuple ]
  end

  # Add a record to active_items (at the beginning)
  # @param type [String] The record type (e.g., "Item", "Link")
  # @param id [Integer] The record ID
  def prepend_active_record(type, id)
    tuple = build_tuple(type, id)
    return if active_items.include?(tuple)
    self.active_items = [ tuple ] + active_items
  end

  # Add a record to inactive_items (at the end)
  # @param type [String] The record type (e.g., "Item", "Link")
  # @param id [Integer] The record ID
  def add_inactive_record(type, id)
    tuple = build_tuple(type, id)
    return if inactive_items.include?(tuple)
    self.inactive_items = inactive_items + [ tuple ]
  end

  # Remove a record from active_items
  # @param type [String] The record type
  # @param id [Integer] The record ID
  def remove_active_record(type, id)
    tuple = build_tuple(type, id)
    self.active_items = active_items.reject { |t| t == tuple }
  end

  # Remove a record from inactive_items
  # @param type [String] The record type
  # @param id [Integer] The record ID
  def remove_inactive_record(type, id)
    tuple = build_tuple(type, id)
    self.inactive_items = inactive_items.reject { |t| t == tuple }
  end

  # Move record from active to inactive
  # @param type [String] The record type
  # @param id [Integer] The record ID
  def deactivate_record(type, id)
    tuple = build_tuple(type, id)
    if active_items.include?(tuple)
      remove_active_record(type, id)
      add_inactive_record(type, id)
    end
  end

  # Move record from inactive to active
  # @param type [String] The record type
  # @param id [Integer] The record ID
  def activate_record(type, id)
    tuple = build_tuple(type, id)
    if inactive_items.include?(tuple)
      remove_inactive_record(type, id)
      add_active_record(type, id)
    end
  end

  # Reorder active items (preserves only tuples present in both arrays)
  # @param ordered_tuples [Array<Hash>] Array of tuples in desired order
  def reorder_active_items(ordered_tuples)
    self.active_items = ordered_tuples & active_items
  end

  # Reorder inactive items (preserves only tuples present in both arrays)
  # @param ordered_tuples [Array<Hash>] Array of tuples in desired order
  def reorder_inactive_items(ordered_tuples)
    self.inactive_items = ordered_tuples & inactive_items
  end

  # Check if a record is in active_items
  # @param type [String] The record type
  # @param id [Integer] The record ID
  # @return [Boolean]
  def active_record?(type, id)
    tuple = build_tuple(type, id)
    active_items.include?(tuple)
  end

  # Check if a record is in inactive_items
  # @param type [String] The record type
  # @param id [Integer] The record ID
  # @return [Boolean]
  def inactive_record?(type, id)
    tuple = build_tuple(type, id)
    inactive_items.include?(tuple)
  end

  # Get all tuples (active + inactive) preserving order
  # @return [Array<Hash>] All tuples
  def all_records
    active_items + inactive_items
  end

  # ============================================================================
  # Backward Compatibility Methods (for Items only)
  # ============================================================================

  # Add an item ID to active_items (backward compatible)
  # @param item_id [Integer] The item ID
  def add_active_item(item_id)
    add_active_record("Item", item_id)
  end

  # Add an item ID to inactive_items (backward compatible)
  # @param item_id [Integer] The item ID
  def add_inactive_item(item_id)
    add_inactive_record("Item", item_id)
  end

  # Remove an item ID from active_items (backward compatible)
  # @param item_id [Integer] The item ID
  def remove_active_item(item_id)
    remove_active_record("Item", item_id)
  end

  # Remove an item ID from inactive_items (backward compatible)
  # @param item_id [Integer] The item ID
  def remove_inactive_item(item_id)
    remove_inactive_record("Item", item_id)
  end

  # Move item from active to inactive (backward compatible)
  # @param item_id [Integer] The item ID
  def deactivate_item(item_id)
    deactivate_record("Item", item_id)
  end

  # Move item from inactive to active (backward compatible)
  # @param item_id [Integer] The item ID
  def activate_item(item_id)
    activate_record("Item", item_id)
  end

  # Check if an item is in active_items (backward compatible)
  # @param item_id [Integer] The item ID
  # @return [Boolean]
  def active_item?(item_id)
    active_record?("Item", item_id)
  end

  # Check if an item is in inactive_items (backward compatible)
  # @param item_id [Integer] The item ID
  # @return [Boolean]
  def inactive_item?(item_id)
    inactive_record?("Item", item_id)
  end

  # Get all items (active + inactive) - backward compatible
  # Returns tuples, not IDs
  # @return [Array<Hash>] All tuples
  def all_items
    all_records
  end

  # ============================================================================
  # Class Methods
  # ============================================================================

  # Find the descendant containing a specific record
  # @param type [String] The record type (e.g., "Item")
  # @param id [Integer] The record ID
  # @return [Descendant, nil] The containing descendant or nil
  def self.containing_record(type, id)
    tuple = { type => id }
    where("active_items @> ? OR inactive_items @> ?", [ tuple ].to_json, [ tuple ].to_json).first
  end

  # Find the descendant containing a specific item (backward compatible)
  # @param item_id [Integer] The item ID
  # @return [Descendant, nil] The containing descendant or nil
  def self.containing_item(item_id)
    containing_record("Item", item_id)
  end

  private

  def ensure_arrays
    self.active_items ||= []
    self.inactive_items ||= []
  end

  def arrays_contain_tuples
    unless active_items.is_a?(Array) && active_items.all? { |item| valid_tuple?(item) }
      errors.add(:active_items, "must be an array of tuples (e.g., [{\"Item\" => 1}])")
    end

    unless inactive_items.is_a?(Array) && inactive_items.all? { |item| valid_tuple?(item) }
      errors.add(:inactive_items, "must be an array of tuples (e.g., [{\"Item\" => 1}])")
    end
  end

  def valid_tuple?(item)
    item.is_a?(Hash) &&
      item.size == 1 &&
      item.keys.first.is_a?(String) &&
      item.values.first.is_a?(Integer)
  end
end
