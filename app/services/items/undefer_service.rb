# frozen_string_literal: true

class Items::UndeferService
  # Service for undeferring (reverting) a deferred item back to todo state.
  #
  # This service:
  # - Validates item is in 'deferred' state
  # - Finds the deferred copy via source_item_id relationship
  # - Validates there's at most one copy
  # - Deletes the deferred copy and all its descendants
  # - Removes copy from its descendant
  # - Updates source item: state=todo, clears deferred_at and deferred_to
  # - Moves source item from inactive_items to active_items in its descendant
  #
  # Returns: { success: Boolean, error: String }

  attr_reader :source_item, :user

  def initialize(source_item:, user:)
    @source_item = source_item
    @user = user
  end

  def call
    # Validate item can be undeferred
    return validation_error unless can_undefer?

    ActiveRecord::Base.transaction do
      # Find the deferred copy
      deferred_copy = source_item.find_deferred_copy

      # If there's a deferred copy, delete it and remove from descendant
      if deferred_copy
        # Validate there's only one copy (should never be more than one)
        validate_single_copy!

        # Remove copy from its descendant before deleting
        remove_from_descendant(deferred_copy)

        # Delete the copy (and all its descendants via dependent: :destroy)
        delete_item_tree(deferred_copy)
      end

      # Update source item: set back to todo and clear defer timestamps
      # Note: Sections are always in todo state, just clear defer timestamps
      if source_item.section?
        source_item.update!(
          deferred_at: nil,
          deferred_to: nil
        )
      else
        source_item.update!(
          state: :todo,
          deferred_at: nil,
          deferred_to: nil
        )
      end

      # Move source item from inactive to active in its descendant
      move_source_to_active

      { success: true }
    end
  rescue StandardError => e
    Rails.logger.error "Undefer item failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { success: false, error: e.message }
  end

  private

  def can_undefer?
    # Items can be undeferred if they're in deferred state OR if they have defer timestamps
    # (sections stay in todo state but have defer timestamps)
    source_item.deferred? || (source_item.deferred_at.present? && source_item.deferred_to.present?)
  end

  def validation_error
    {
      success: false,
      error: "Only deferred items can be undeferred. This item has not been deferred."
    }
  end

  def validate_single_copy!
    # Check all copies (should only be 0 or 1)
    all_copies = source_item.find_all_copies
    if all_copies.count > 1
      Rails.logger.error "CRITICAL: Multiple deferred copies found for item #{source_item.id}. Count: #{all_copies.count}"
      # Log all copy IDs for debugging
      Rails.logger.error "Copy IDs: #{all_copies.pluck(:id).join(', ')}"
      raise StandardError, "Multiple deferred copies found. This should never happen."
    end
  end

  def remove_from_descendant(item)
    # Find which descendant contains this item
    containing_descendant = Descendant.containing_item(item.id)
    return unless containing_descendant

    # Remove from whichever array it's in
    if containing_descendant.active_item?(item.id)
      containing_descendant.remove_active_item(item.id)
      containing_descendant.save!
    elsif containing_descendant.inactive_item?(item.id)
      containing_descendant.remove_inactive_item(item.id)
      containing_descendant.save!
    end
  end

  def delete_item_tree(item)
    # Recursively delete all nested items first
    if item.descendant&.active_items&.any? || item.descendant&.inactive_items&.any?
      all_item_ids = []
      all_item_ids += item.descendant.extract_active_item_ids if item.descendant.active_items&.any?
      all_item_ids += item.descendant.extract_inactive_item_ids if item.descendant.inactive_items&.any?

      nested_items = Item.where(id: all_item_ids)
      nested_items.each do |nested_item|
        delete_item_tree(nested_item)
      end
    end

    # Delete the item (this will cascade delete its descendant via dependent: :destroy)
    item.destroy!
  end

  def move_source_to_active
    # Find which descendant contains this item
    containing_descendant = Descendant.containing_item(source_item.id)
    return unless containing_descendant

    # Only move if in inactive items
    return unless containing_descendant.inactive_item?(source_item.id)

    # Move from inactive to active
    containing_descendant.remove_inactive_item(source_item.id)
    containing_descendant.add_active_item(source_item.id)
    containing_descendant.save!
  end
end
