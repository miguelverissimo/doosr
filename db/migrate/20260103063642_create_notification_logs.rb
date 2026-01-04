class CreateNotificationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :item, null: true, foreign_key: true
      t.references :push_subscription, null: true, foreign_key: true
      t.string :notification_type, null: false
      t.string :status, null: false
      t.text :error_message
      t.jsonb :payload
      t.datetime :sent_at

      t.timestamps
    end

    add_index :notification_logs, [ :user_id, :created_at ]
    add_index :notification_logs, [ :notification_type, :status ]
  end
end
