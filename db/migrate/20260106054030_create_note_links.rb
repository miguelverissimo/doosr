class CreateNoteLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :note_links do |t|
      t.references :note, null: false, foreign_key: true
      t.references :linked_note, null: false, foreign_key: { to_table: :notes }

      t.timestamps
    end

    add_index :note_links, [ :note_id, :linked_note_id ], unique: true
  end
end
