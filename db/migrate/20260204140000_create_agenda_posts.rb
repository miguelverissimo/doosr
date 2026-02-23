class CreateAgendaPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :agenda_posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :type, null: false
      t.jsonb :data, null: false, default: {}

      t.timestamps
    end

    add_index :agenda_posts, [ :user_id, :type, :created_at ]
  end
end
