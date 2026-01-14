class AddJournalEncryptionFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :journal_password_digest, :string
    add_column :users, :journal_encryption_salt, :string
    add_column :users, :encrypted_seed_phrase, :text
    add_column :users, :journal_protection_enabled, :boolean, default: false
  end
end
