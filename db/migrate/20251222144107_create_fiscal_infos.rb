class CreateFiscalInfos < ActiveRecord::Migration[8.1]
  def change
    create_table :fiscal_infos do |t|
      t.references :user, null: false, foreign_key: true
      t.references :address, null: true, foreign_key: true
      t.string :kind, null: false
      t.string :title
      t.string :tax_number

      t.timestamps
    end
  end
end
