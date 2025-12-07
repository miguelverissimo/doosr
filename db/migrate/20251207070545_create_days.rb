class CreateDays < ActiveRecord::Migration[8.1]
  def change
    create_table :days do |t|
      # User association - each day belongs to a user
      t.references :user, null: false, foreign_key: true

      # The date this Day represents (date only, not datetime)
      t.date :date, null: false

      # State: 0 = open, 1 = closed (using integer for enum)
      t.integer :state, default: 0, null: false

      # State change timestamps
      t.datetime :closed_at
      t.datetime :reopened_at

      # Import tracking - self-referential foreign keys
      # imported_from_day_id: the Day this was imported FROM
      # imported_to_day_id: the Day this was imported TO
      t.bigint :imported_from_day_id
      t.bigint :imported_to_day_id
      t.datetime :imported_at

      t.timestamps
    end

    # Foreign keys for import tracking (self-referential)
    add_foreign_key :days, :days, column: :imported_from_day_id, on_delete: :nullify
    add_foreign_key :days, :days, column: :imported_to_day_id, on_delete: :nullify

    # Indexes for efficient queries (user_id already indexed by t.references)
    add_index :days, :date
    add_index :days, :state
    add_index :days, :imported_from_day_id
    add_index :days, :imported_to_day_id

    # Unique constraint: one Day per user per date
    add_index :days, [:user_id, :date], unique: true, name: 'index_days_on_user_and_date'
  end
end
