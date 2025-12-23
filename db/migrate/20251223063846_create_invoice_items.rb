class CreateInvoiceItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.references :invoice, null: false, foreign_key: true
      t.string :description
      t.float :quantity
      t.string :unit
      t.integer :unit_price
      t.integer :subtotal
      t.float :discount_rate
      t.integer :discount_amount
      t.references :tax_bracket, null: false, foreign_key: true
      t.float :tax_rate
      t.integer :tax_amount
      t.integer :amount
      t.boolean :display_quantity
      t.string :tax_exemption_motive

      t.timestamps
    end
  end
end
