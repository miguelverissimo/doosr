class CreateJournals < ActiveRecord::Migration[8.1]
  def change
    create_table :journals do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.date :date, null: false

      t.timestamps

      t.index [ :user_id, :date ], unique: true
    end
  end
end
