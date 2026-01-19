class AddCategoryPatternToBankTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :bank_transactions, :category_pattern, null: true, foreign_key: true
  end
end
