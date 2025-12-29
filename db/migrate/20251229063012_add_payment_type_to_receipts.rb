class AddPaymentTypeToReceipts < ActiveRecord::Migration[8.1]
  def change
    add_column :receipts, :payment_type, :string, default: "total", null: false
  end
end
