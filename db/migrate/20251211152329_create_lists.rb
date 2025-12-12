class CreateLists < ActiveRecord::Migration[8.1]
  def change
    create_table :lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :list_type, default: 0, null: false
      t.integer :visibility, default: 0, null: false
      t.string :slug, null: false
      t.references :descendant, foreign_key: true

      t.timestamps
    end

    add_index :lists, :slug, unique: true
    add_index :lists, :list_type
  end
end
