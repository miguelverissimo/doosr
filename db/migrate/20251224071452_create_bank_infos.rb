class CreateBankInfos < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_infos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false, default: "user"
      t.string :name
      t.string :account_number
      t.string :routing_number
      t.string :iban
      t.string :swift_bic

      t.timestamps
    end
  end
end
