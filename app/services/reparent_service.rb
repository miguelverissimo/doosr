# frozen_string_literal: true

class ReparentService
  def initialize(record:, record_type:, target_descendant:)
    @record = record
    @record_type = record_type # "Item" or "Note"
    @target_descendant = target_descendant
  end

  def call
    # Find and remove record from the descendant that contains it
    remove_from_current_descendant

    # Add record to target descendant
    add_to_target_descendant

    true
  end

  private

  def remove_from_current_descendant
    containing_descendant = find_containing_descendant
    if containing_descendant
      containing_descendant.remove_active_record(@record_type, @record.id)
      containing_descendant.remove_inactive_record(@record_type, @record.id)
      containing_descendant.save!
    end
  end

  def find_containing_descendant
    case @record_type
    when "Item"
      Descendant.containing_item(@record.id)
    when "Note"
      # Notes can be in multiple descendants, find the first one
      @record.parent_descendants.first
    end
  end

  def add_to_target_descendant
    # For items, check state (done/dropped go to inactive)
    # For notes, always add to active
    if @record_type == "Item" && (@record.done? || @record.dropped?)
      @target_descendant.add_inactive_record(@record_type, @record.id)
    else
      @target_descendant.add_active_record(@record_type, @record.id)
    end
    @target_descendant.save!
  end
end
