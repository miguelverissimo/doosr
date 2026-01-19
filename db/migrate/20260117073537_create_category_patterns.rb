class CreateCategoryPatterns < ActiveRecord::Migration[8.1]
  def change
    create_table :category_patterns do |t|
      t.string :pattern, null: false
      t.references :category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :category_patterns, [ :user_id, :pattern ], unique: true
  end
end
