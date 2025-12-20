class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.references :address, null: false, foreign_key: true
      t.string :telephone
      t.string :contact_name
      t.string :contact_email
      t.string :contact_phone
      t.string :billing_contact_name
      t.string :billing_email
      t.string :billing_phone
      t.text :notes
      t.json :metadata

      t.timestamps
    end
  end
end
