class AddEncryptedContentToJournalFragments < ActiveRecord::Migration[8.1]
  def change
    add_column :journal_fragments, :encrypted_content, :text
    add_column :journal_fragments, :content_iv, :string
  end
end
