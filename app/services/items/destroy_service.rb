# frozen_string_literal: true

module Items
  class DestroyService
    def initialize(item:)
      @item = item
    end

    def call
      delete_item_with_descendants(@item)
      { success: true }
    rescue StandardError => e
      { success: false, error: e.message }
    end

    private

    def delete_item_with_descendants(item)
      if item.descendant
        descendant = item.descendant
        all_child_ids = descendant.extract_active_item_ids + descendant.extract_inactive_item_ids
        child_items = Item.where(id: all_child_ids).includes(:descendant)

        child_items.each do |child_item|
          delete_item_with_descendants(child_item)
        end

        descendant.destroy!
      end

      parent_descendant = Descendant.containing_item(item.id)
      if parent_descendant
        parent_descendant.remove_active_item(item.id)
        parent_descendant.remove_inactive_item(item.id)
        parent_descendant.save!
      end

      item.destroy!
    end
  end
end
