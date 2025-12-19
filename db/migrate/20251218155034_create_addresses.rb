class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :address_type, default: :user, null: false
      t.string :state, default: :active, null: false
      t.string :name, null: false
      t.text :full_address, null: false
      t.string :country, null: false

      t.timestamps
    end
  end
end
