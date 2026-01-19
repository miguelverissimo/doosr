class AddRecurringGroupToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :bank_transactions, :recurring_group, null: true, foreign_key: true
  end
end
