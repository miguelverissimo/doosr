class CreateTaxBrackets < ActiveRecord::Migration[8.1]
  def change
    create_table :tax_brackets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :percentage, null: false
      t.string :legal_reference

      t.timestamps null: false
    end

    add_index :tax_brackets, [:user_id, :name], unique: true
  end
end
