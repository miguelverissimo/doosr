# frozen_string_literal: true

class Items::DropSectionService
  # Service for dropping a section and all its active descendants.
  #
  # This service:
  # - Validates the item is a section in 'todo' state
  # - Traverses the section's descendant tree (only active items)
  # - Drops every active item in the tree recursively
  # - Drops the section itself
  #
  # Returns: { success: Boolean, dropped_count: Integer, error: String }

  attr_reader :section, :user

  def initialize(section:, user:)
    @section = section
    @user = user
  end

  def call
    return validation_error unless can_drop?

    dropped_count = 0

    ActiveRecord::Base.transaction do
      # First, drop all active descendants recursively
      dropped_count = drop_active_descendants_recursively(section.descendant)

      # Then drop the section itself
      section.set_section_dropped!
      dropped_count += 1

      {
        success: true,
        dropped_count: dropped_count
      }
    end
  rescue StandardError => e
    Rails.logger.error "Drop section failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { success: false, error: e.message }
  end

  private

  def can_drop?
    section.section? && section.todo?
  end

  def validation_error
    if !section.section?
      { success: false, error: "Only sections can be dropped with this service" }
    else
      { success: false, error: "Only sections in 'todo' state can be dropped. Current state: #{section.state}" }
    end
  end

  # Recursively drop all active items in a descendant tree
  def drop_active_descendants_recursively(descendant)
    return 0 unless descendant

    dropped_count = 0
    active_item_ids = descendant.extract_active_item_ids

    return 0 if active_item_ids.empty?

    items = Item.where(id: active_item_ids).includes(:descendant)

    items.each do |item|
      # First, recursively drop the item's descendants (if any)
      if item.descendant
        dropped_count += drop_active_descendants_recursively(item.descendant)
      end

      # Then drop the item itself
      if item.section?
        item.set_section_dropped!
      elsif item.can_be_completed?
        item.set_dropped!
      end

      dropped_count += 1
    end

    dropped_count
  end

  # Count active items in the descendant tree (for confirmation message)
  def count_active_descendants(descendant)
    return 0 unless descendant

    count = 0
    active_item_ids = descendant.extract_active_item_ids

    return 0 if active_item_ids.empty?

    items = Item.where(id: active_item_ids).includes(:descendant)

    items.each do |item|
      count += 1

      if item.descendant
        count += count_active_descendants(item.descendant)
      end
    end

    count
  end
end
