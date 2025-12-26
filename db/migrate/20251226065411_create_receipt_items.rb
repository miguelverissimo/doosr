class CreateReceiptItems < ActiveRecord::Migration[8.1]
  def change
    create_table :receipt_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :reference
      t.string :kind
      t.string :description
      t.string :unit
      t.integer :gross_unit_price
      t.references :tax_bracket, null: false, foreign_key: true
      t.string :exemption_motive
      t.integer :unit_price_with_tax
      t.boolean :active

      t.timestamps
    end
  end
end
