class CreateInvoiceTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_templates do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :description
      t.references :accounting_logo, null: false, foreign_key: true
      t.references :provider_address, null: false, foreign_key: { to_table: :addresses }
      t.references :customer, null: false, foreign_key: true
      t.string :currency

      t.timestamps
    end
  end
end
