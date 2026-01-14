class AddJournalSessionTimeoutToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :journal_session_timeout_minutes, :integer, default: 30, null: false
  end
end
