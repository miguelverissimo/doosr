# frozen_string_literal: true

module Items
  class MoveService
    def initialize(item:, direction:)
      @item = item
      @direction = direction
    end

    def call
      tuple = { "Item" => @item.id }
      containing_descendant = Descendant.where("active_items @> ?", [ tuple ].to_json).first

      unless containing_descendant
        return { success: false, error: "Item not found in any active list" }
      end

      active_items = containing_descendant.active_items
      current_index = active_items.index(tuple)

      unless current_index
        return { success: false, error: "Item not found in active items" }
      end

      new_index = @direction == "up" ? current_index - 1 : current_index + 1

      unless new_index >= 0 && new_index < active_items.length
        return { success: false, error: "Cannot move item #{@direction}" }
      end

      active_items[current_index], active_items[new_index] = active_items[new_index], active_items[current_index]
      containing_descendant.active_items = active_items
      containing_descendant.save!

      { success: true, item: @item }
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end
end
