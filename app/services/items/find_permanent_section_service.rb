# frozen_string_literal: true

class Items::FindPermanentSectionService
  # Service to find which permanent section (if any) an item belongs to
  # Walks up the tree from the item to find a permanent section ancestor
  #
  # Returns: The permanent section Item, or nil if not in a permanent section tree

  attr_reader :item

  def initialize(item:)
    @item = item
  end

  def call
    # Find which descendant contains this item
    containing_descendant = Descendant.containing_item(item.id)
    return nil unless containing_descendant

    # Walk up the tree
    current_descendant = containing_descendant

    loop do
      # Check if this descendant belongs to an item
      descendable = current_descendant.descendable

      # If descendable is a Day, we've reached the top without finding a permanent section
      return nil if descendable.is_a?(Day)

      # If descendable is a List, we've reached the top without finding a permanent section
      return nil if descendable.is_a?(List)

      # If descendable is an Item, check if it's a permanent section
      if descendable.is_a?(Item)
        if descendable.section? && descendable.extra_data&.dig("permanent_section")
          return descendable
        end

        # Continue walking up - find the descendant that contains this item
        parent_descendant = Descendant.containing_item(descendable.id)
        return nil unless parent_descendant

        current_descendant = parent_descendant
      else
        # Unknown descendable type
        return nil
      end
    end
  end
end
