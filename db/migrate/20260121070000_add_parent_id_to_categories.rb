# frozen_string_literal: true

class AddParentIdToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :parent_id, :bigint, null: true
    add_foreign_key :categories, :categories, column: :parent_id, on_delete: :nullify

    add_index :categories, :parent_id

    # Remove the old unique constraint and add new one that accounts for parent_id
    remove_index :categories, [ :user_id, :name ]
    add_index :categories, [ :user_id, :name, :parent_id ], unique: true, name: "index_categories_on_user_name_parent"
  end
end
