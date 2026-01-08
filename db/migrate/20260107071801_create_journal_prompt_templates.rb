class CreateJournalPromptTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_prompt_templates do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.text :prompt_text, null: false
      t.jsonb :schedule_rule, default: {}, null: false
      t.boolean :active, default: true, null: false

      t.timestamps

      t.index :schedule_rule, using: :gin
    end
  end
end
