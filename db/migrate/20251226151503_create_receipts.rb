class CreateReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :receipts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :invoice, null: true, foreign_key: true
      t.string :kind
      t.string :reference
      t.datetime :issue_date
      t.datetime :payment_date
      t.integer :value

      t.timestamps
    end
  end
end
