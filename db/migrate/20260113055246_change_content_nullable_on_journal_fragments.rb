class ChangeContentNullableOnJournalFragments < ActiveRecord::Migration[8.1]
  def change
    change_column_null :journal_fragments, :content, true
  end
end
