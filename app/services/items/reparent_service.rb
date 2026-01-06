# frozen_string_literal: true

module Items
  class ReparentService
    def initialize(item:, target_descendant:)
      @item = item
      @target_descendant = target_descendant
    end

    def call
      # Delegate to generic ReparentService
      ::ReparentService.new(
        record: @item,
        record_type: "Item",
        target_descendant: @target_descendant
      ).call
    end
  end
end
