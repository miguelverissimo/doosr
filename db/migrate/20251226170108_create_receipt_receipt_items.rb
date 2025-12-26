class CreateReceiptReceiptItems < ActiveRecord::Migration[8.1]
  def change
    create_table :receipt_receipt_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :receipt, null: false, foreign_key: true
      t.references :receipt_item, null: false, foreign_key: true
      t.integer :quantity
      t.integer :gross_value
      t.float :tax_percentage
      t.integer :value_with_tax

      t.timestamps
    end
  end
end
