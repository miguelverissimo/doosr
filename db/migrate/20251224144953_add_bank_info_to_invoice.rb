class AddBankInfoToInvoice < ActiveRecord::Migration[8.1]
  def change
    add_reference :invoices, :bank_info, null: true, foreign_key: true
  end
end
