class CreateDescendants < ActiveRecord::Migration[8.1]
  def change
    create_table :descendants do |t|
      # Polymorphic association - can belong to Day, or any other model
      t.references :descendable, polymorphic: true, null: false, index: false

      # JSONB arrays for storing ordered item IDs
      # Using JSONB provides native array support, indexability, and preserves order
      t.jsonb :active_items, default: [], null: false
      t.jsonb :inactive_items, default: [], null: false

      t.timestamps
    end

    # Composite index for efficient polymorphic lookups
    add_index :descendants, [:descendable_type, :descendable_id],
              name: 'index_descendants_on_descendable',
              unique: true

    # GIN indexes for efficient JSONB array containment queries
    # Allows fast queries like: "find descendants where active_items contains [1, 2]"
    add_index :descendants, :active_items, using: :gin
    add_index :descendants, :inactive_items, using: :gin
  end
end
