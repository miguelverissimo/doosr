class CreateEphemeries < ActiveRecord::Migration[8.1]
  def change
    create_table :ephemeries do |t|
      t.datetime :start, null: false
      t.datetime :end, null: false
      t.datetime :strongest
      t.string :aspect, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_index :ephemeries, [ :start, :end ]
  end
end
