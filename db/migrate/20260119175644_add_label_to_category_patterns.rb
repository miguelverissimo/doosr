class AddLabelToCategoryPatterns < ActiveRecord::Migration[8.1]
  def change
    add_column :category_patterns, :label, :string
  end
end
