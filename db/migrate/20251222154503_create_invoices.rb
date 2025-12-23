class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.references :invoice_template, null: true, foreign_key: true
      t.string :state, null: false, default: "draft"
      t.integer :number, null: false
      t.integer :year, null: false
      t.string :display_number, null: false
      t.references :provider, null: false, foreign_key: { to_table: :addresses }
      t.references :customer, null: false, foreign_key: true
      t.string :currency, null: false
      t.datetime :issued_at
      t.datetime :due_at
      t.integer :subtotal
      t.integer :discount
      t.integer :tax
      t.integer :total
      t.text :notes
      t.jsonb :metadata

      t.timestamps

      t.index [:user_id, :year, :number], unique: true
      t.index [:user_id, :display_number], unique: true
      t.index [:user_id, :state]
    end
  end
end
