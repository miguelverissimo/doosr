# frozen_string_literal: true

# Descendant is a polymorphic model that stores ordered lists of item IDs
# for any parent model (Day, or other models in the future).
#
# It maintains two separate ordered arrays:
# - active_items: IDs of active/visible items in display order
# - inactive_items: IDs of inactive/hidden items in display order
#
# Example usage:
#   day = Day.find(1)
#   day.descendant.active_items << 123    # Add item ID 123 to active items
#   day.descendant.active_items           # => [123, 456, 789] (ordered)
#   day.descendant.save
#
class Descendant < ApplicationRecord
  # Polymorphic association - can belong to Day or any other model
  belongs_to :descendable, polymorphic: true

  # Validations
  # Note: We don't use presence: true because empty arrays should be valid
  # The database enforces NOT NULL, and our custom validation ensures they're arrays
  validate :arrays_contain_integers

  # Ensure active_items and inactive_items are always arrays
  after_initialize :ensure_arrays

  # Add an item ID to active_items (at the end)
  def add_active_item(item_id)
    return if active_items.include?(item_id)
    self.active_items = active_items + [item_id]
  end

  # Add an item ID to inactive_items (at the end)
  def add_inactive_item(item_id)
    return if inactive_items.include?(item_id)
    self.inactive_items = inactive_items + [item_id]
  end

  # Remove an item ID from active_items
  def remove_active_item(item_id)
    self.active_items = active_items.reject { |id| id == item_id }
  end

  # Remove an item ID from inactive_items
  def remove_inactive_item(item_id)
    self.inactive_items = inactive_items.reject { |id| id == item_id }
  end

  # Move item from active to inactive
  def deactivate_item(item_id)
    if active_items.include?(item_id)
      remove_active_item(item_id)
      add_inactive_item(item_id)
    end
  end

  # Move item from inactive to active
  def activate_item(item_id)
    if inactive_items.include?(item_id)
      remove_inactive_item(item_id)
      add_active_item(item_id)
    end
  end

  # Reorder active items
  def reorder_active_items(ordered_ids)
    self.active_items = ordered_ids & active_items
  end

  # Reorder inactive items
  def reorder_inactive_items(ordered_ids)
    self.inactive_items = ordered_ids & inactive_items
  end

  # Check if an item is in active_items
  def active_item?(item_id)
    active_items.include?(item_id)
  end

  # Check if an item is in inactive_items
  def inactive_item?(item_id)
    inactive_items.include?(item_id)
  end

  # Get all items (active + inactive) preserving order
  def all_items
    active_items + inactive_items
  end

  # Class method to find the descendant containing a specific item ID
  def self.containing_item(item_id)
    where("active_items @> ? OR inactive_items @> ?", [item_id].to_json, [item_id].to_json).first
  end

  private

  def ensure_arrays
    self.active_items ||= []
    self.inactive_items ||= []
  end

  def arrays_contain_integers
    unless active_items.is_a?(Array) && active_items.all? { |item| item.is_a?(Integer) }
      errors.add(:active_items, "must be an array of integers")
    end

    unless inactive_items.is_a?(Array) && inactive_items.all? { |item| item.is_a?(Integer) }
      errors.add(:inactive_items, "must be an array of integers")
    end
  end
end
