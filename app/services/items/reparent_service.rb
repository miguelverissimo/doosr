# frozen_string_literal: true

module Items
  class ReparentService
    def initialize(item:, target_descendant:)
      @item = item
      @target_descendant = target_descendant
    end

    def call
      # Find and remove item from the descendant that contains it
      remove_from_current_descendant

      # Add item to target descendant
      add_to_target_descendant

      true
    end

    private

    def remove_from_current_descendant
      containing_descendant = Descendant.containing_item(@item.id)
      if containing_descendant
        containing_descendant.remove_active_item(@item.id)
        containing_descendant.remove_inactive_item(@item.id)
        containing_descendant.save!
      end
    end

    def add_to_target_descendant
      if @item.done? || @item.dropped?
        @target_descendant.add_inactive_item(@item.id)
      else
        @target_descendant.add_active_item(@item.id)
      end
      @target_descendant.save!
    end
  end
end
