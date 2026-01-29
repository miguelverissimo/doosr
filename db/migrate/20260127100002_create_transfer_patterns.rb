# frozen_string_literal: true

class CreateTransferPatterns < ActiveRecord::Migration[8.0]
  def change
    create_table :transfer_patterns do |t|
      t.references :user, null: false, foreign_key: true
      t.string :pattern, null: false
      t.string :label
      t.timestamps
    end

    add_index :transfer_patterns, [ :user_id, :pattern ], unique: true
  end
end
