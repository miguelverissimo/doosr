class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      # Associations
      t.references :user, null: false, foreign_key: true

      # Core fields
      t.string :title, null: false
      t.integer :item_type, default: 0, null: false  # enum: completable, section, reusable, trackable
      t.integer :state, default: 0, null: false      # enum: todo, done, dropped, deferred

      # State tracking timestamps
      t.datetime :done_at
      t.datetime :dropped_at
      t.datetime :deferred_at
      t.datetime :deferred_to

      # Self-referential associations
      t.bigint :source_item_id        # The item this was imported from
      t.bigint :recurring_next_item_id # The next item in recurrence chain

      # Recurrence
      t.string :recurrence_rule

      # Nesting support via Descendant
      t.references :descendant, foreign_key: true

      # Extra metadata
      t.jsonb :extra_data, default: {}, null: false

      t.timestamps
    end

    # Self-referential foreign keys
    add_foreign_key :items, :items, column: :source_item_id, on_delete: :nullify
    add_foreign_key :items, :items, column: :recurring_next_item_id, on_delete: :nullify

    # Indexes for performance (user_id and descendant_id already indexed by t.references)
    add_index :items, :item_type
    add_index :items, :state
    add_index :items, :source_item_id
    add_index :items, :recurring_next_item_id
    add_index :items, :extra_data, using: :gin
  end
end
