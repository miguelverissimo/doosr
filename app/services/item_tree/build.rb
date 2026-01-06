# app/services/item_tree/build.rb
module ItemTree
  class Build
    Node = Struct.new(:label, :item, :list, :checklist, :note, :children, keyword_init: true) do
      def initialize(label:, item: nil, list: nil, checklist: nil, note: nil, children: [])
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
        return [ Node.new(label: "(cycle detected)", children: []) ]
      end

      @descendant_stack[descendant.id] = true

      # Get all tuples (items and lists) in order
      all_tuples = descendant.active_items + descendant.inactive_items
      return [] if all_tuples.empty?

      # Extract IDs by type
      item_ids = descendant.extract_active_ids_by_type("Item") +
                 descendant.extract_inactive_ids_by_type("Item")
      list_ids = descendant.extract_active_ids_by_type("List") +
                 descendant.extract_inactive_ids_by_type("List")
      checklist_ids = descendant.extract_active_ids_by_type("Checklist") +
                      descendant.extract_inactive_ids_by_type("Checklist")
      note_ids = descendant.extract_active_ids_by_type("Note") +
                 descendant.extract_inactive_ids_by_type("Note")

      # Fetch items, lists, checklists, and notes
      items_by_id = fetch_items_indexed(item_ids)
      lists_by_id = fetch_lists_indexed(list_ids)
      checklists_by_id = fetch_checklists_indexed(checklist_ids)
      notes_by_id = fetch_notes_indexed(note_ids)

      # Process tuples in order, creating nodes based on type
      all_tuples.filter_map do |tuple|
        type, id = tuple.first

        case type
        when "Item"
          item = items_by_id[id]
          next unless item # stale reference => skip

          # Check for item-level cycle (item appears in its own descendant tree)
          if @item_stack[item.id]
            return [ Node.new(label: "(cycle detected)", children: []) ]
          end

          @item_stack[item.id] = true
          children = build_children_for_descendant(item.descendant)
          @item_stack.delete(item.id)

          Node.new(
            label: item.title,
            item: item,
            children: children
          )

        when "List"
          list = lists_by_id[id]
          next unless list # stale reference => skip

          # Lists are leaf nodes in day context (no children rendered)
          Node.new(
            label: list.title,
            list: list,
            children: []
          )

        when "Checklist"
          checklist = checklists_by_id[id]
          next unless checklist # stale reference => skip

          # Checklists are leaf nodes in day context (no children rendered)
          Node.new(
            label: checklist.name,
            checklist: checklist,
            children: []
          )

        when "Note"
          note = notes_by_id[id]
          next unless note # stale reference => skip

          # Notes are leaf nodes (no children)
          Node.new(
            label: note.content_preview,
            note: note,
            children: []
          )
        end
      end
    ensure
      @descendant_stack.delete(descendant.id) if descendant&.id
    end

    def fetch_items_indexed(ids)
      return {} if ids.empty?
      # Polymorphic-safe: Item has_one :descendant
      Item.where(id: ids).includes(:descendant).index_by(&:id)
    end

    def fetch_lists_indexed(ids)
      return {} if ids.empty?
      # Lists also have descendants
      List.where(id: ids).includes(:descendant).index_by(&:id)
    end

    def fetch_checklists_indexed(ids)
      return {} if ids.empty?
      Checklist.where(id: ids).index_by(&:id)
    end

    def fetch_notes_indexed(ids)
      return {} if ids.empty?
      Note.where(id: ids).index_by(&:id)
    end
  end
end
