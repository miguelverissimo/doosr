class CreateAccountingItems < ActiveRecord::Migration[8.1]
  def change
    create_table :accounting_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :reference, null: false
      t.string :name, null: false
      t.string :kind, null: false
      t.string :description
      t.string :unit, null: false
      t.integer :price, null: false
      t.string :currency, null: false, default: "EUR"
      t.boolean :convert_currency, null: false, default: false
      t.string :detail

      t.timestamps
    end
  end
end
