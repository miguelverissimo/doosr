class CreateAccountingLogos < ActiveRecord::Migration[8.1]
  def change
    create_table :accounting_logos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
