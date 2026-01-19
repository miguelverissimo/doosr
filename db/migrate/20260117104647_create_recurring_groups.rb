class CreateRecurringGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :recurring_groups do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description_pattern, null: false
      t.decimal :average_amount, precision: 15, scale: 2, null: false
      t.string :frequency, null: false
      t.date :last_occurrence
      t.date :expected_next
      t.boolean :active, default: true, null: false
      t.integer :occurrence_count, default: 0, null: false

      t.timestamps
    end

    add_index :recurring_groups, [ :user_id, :description_pattern ], unique: true
  end
end
