# app/services/item_tree/build.rb
module ItemTree
  class Build
    Node = Struct.new(:label, :item, :children, keyword_init: true) do
      def initialize(label:, item: nil, children: [])
        super
      end
    end

    def self.call(root_descendant, root_label: "root")
      new(root_descendant, root_label:).call
    end

    def initialize(root_descendant, root_label:)
      @root_descendant = root_descendant
      @root_label = root_label
      @descendant_stack = {} # cycle detection on current DFS path (tracks descendant IDs)
      @item_stack = {} # cycle detection on current DFS path (tracks item IDs)
    end

    def call
      Node.new(label: @root_label, children: build_children_for_descendant(@root_descendant))
    end

    private

    def build_children_for_descendant(descendant)
      return [] if descendant.nil?

      if @descendant_stack[descendant.id]
        return [Node.new(label: "(cycle detected)", children: [])]
      end

      @descendant_stack[descendant.id] = true

      ids = ordered_item_ids(descendant)
      return [] if ids.empty?

      items_by_id = fetch_items_indexed(ids)

      ids.filter_map do |id|
        item = items_by_id[id]
        next unless item # stale reference => skip

        # Check for item-level cycle (item appears in its own descendant tree)
        if @item_stack[item.id]
          return [Node.new(label: "(cycle detected)", children: [])]
        end

        @item_stack[item.id] = true
        children = build_children_for_descendant(item.descendant)
        @item_stack.delete(item.id)

        Node.new(
          label: item.title, # adjust if your display field differs
          item: item,
          children: children
        )
      end
    ensure
      @descendant_stack.delete(descendant.id) if descendant&.id
    end

    def ordered_item_ids(descendant)
      descendant.extract_active_item_ids + descendant.extract_inactive_item_ids
    end

    def fetch_items_indexed(ids)
      # Polymorphic-safe: Item has_one :descendant
      Item.where(id: ids).includes(:descendant).index_by(&:id)
    end
  end
end