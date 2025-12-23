class CreateInvoiceTemplateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_template_items do |t|
      t.references :invoice_template, null: false, foreign_key: { to_table: :invoice_templates }
      t.references :user, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: { to_table: :accounting_items }
      t.references :tax_bracket, null: false, foreign_key: true
      t.string :description
      t.float :quantity
      t.string :unit
      t.float :discount_rate

      t.timestamps
    end
  end
end
