class CreateJournalPrompts < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_prompts do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :journal, null: false, foreign_key: true, index: true
      t.text :prompt_text, null: false

      t.timestamps
    end
  end
end
