class CreateChecklists < ActiveRecord::Migration[8.1]
  def change
    create_table :checklists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :kind, null: false, default: "template" # template, checklist
      t.bigint :template_id # self-reference to a template checklist
      t.string :flow, null: false, default: "sequential" # sequential, parallel
      t.jsonb :items, default: [] # items in the checklist
      t.jsonb :metadata, default: {} # metadata about the checklist

      t.timestamps
    end

    # self-reference foreign key
    add_foreign_key :checklists, :checklists, column: :template_id, on_delete: :nullify

    # indexes
    add_index :checklists, :template_id
    add_index :checklists, :kind
    add_index :checklists, :flow
    add_index :checklists, :items, using: :gin
  end
end
