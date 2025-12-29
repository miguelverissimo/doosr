class AddCompletesPaymentToReceipts < ActiveRecord::Migration[8.1]
  def change
    add_column :receipts, :completes_payment, :boolean, default: false, null: false
  end
end
