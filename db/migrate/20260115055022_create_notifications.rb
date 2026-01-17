# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.datetime :remind_at, null: false
      t.string :title
      t.text :body
      t.string :status, null: false, default: "pending"
      t.datetime :sent_at
      t.datetime :read_at
      t.string :channels, array: true, default: [ "push", "in_app" ]
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :notifications, :status
    add_index :notifications, :remind_at
    add_index :notifications, [ :status, :remind_at ]
  end
end
