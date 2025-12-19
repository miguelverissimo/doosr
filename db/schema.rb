# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_18_155034) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "address_type", default: "user", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.text "full_address", null: false
    t.string "name", null: false
    t.string "state", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "days", force: :cascade do |t|
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.datetime "imported_at"
    t.bigint "imported_from_day_id"
    t.bigint "imported_to_day_id"
    t.datetime "reopened_at"
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["date"], name: "index_days_on_date"
    t.index ["imported_from_day_id"], name: "index_days_on_imported_from_day_id"
    t.index ["imported_to_day_id"], name: "index_days_on_imported_to_day_id"
    t.index ["state"], name: "index_days_on_state"
    t.index ["user_id", "date"], name: "index_days_on_user_and_date", unique: true
    t.index ["user_id"], name: "index_days_on_user_id"
  end

  create_table "descendants", force: :cascade do |t|
    t.jsonb "active_items", default: [], null: false
    t.datetime "created_at", null: false
    t.bigint "descendable_id", null: false
    t.string "descendable_type", null: false
    t.jsonb "inactive_items", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["active_items"], name: "index_descendants_on_active_items", using: :gin
    t.index ["descendable_type", "descendable_id"], name: "index_descendants_on_descendable", unique: true
    t.index ["inactive_items"], name: "index_descendants_on_inactive_items", using: :gin
  end

  create_table "ephemeries", force: :cascade do |t|
    t.string "aspect", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.datetime "end", null: false
    t.datetime "start", null: false
    t.datetime "strongest"
    t.datetime "updated_at", null: false
    t.index ["start", "end"], name: "index_ephemeries_on_start_and_end"
  end

  create_table "items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deferred_at"
    t.datetime "deferred_to"
    t.bigint "descendant_id"
    t.datetime "done_at"
    t.datetime "dropped_at"
    t.jsonb "extra_data", default: {}, null: false
    t.integer "item_type", default: 0, null: false
    t.string "recurrence_rule"
    t.bigint "recurring_next_item_id"
    t.bigint "source_item_id"
    t.integer "state", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["descendant_id"], name: "index_items_on_descendant_id"
    t.index ["extra_data"], name: "index_items_on_extra_data", using: :gin
    t.index ["item_type"], name: "index_items_on_item_type"
    t.index ["recurring_next_item_id"], name: "index_items_on_recurring_next_item_id"
    t.index ["source_item_id"], name: "index_items_on_source_item_id"
    t.index ["state"], name: "index_items_on_state"
    t.index ["user_id"], name: "index_items_on_user_id"
  end

  create_table "lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "descendant_id"
    t.integer "list_type", default: 0, null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["descendant_id"], name: "index_lists_on_descendant_id"
    t.index ["list_type"], name: "index_lists_on_list_type"
    t.index ["slug"], name: "index_lists_on_slug", unique: true
    t.index ["user_id"], name: "index_lists_on_user_id"
  end

  create_table "tax_brackets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "legal_reference"
    t.string "name", null: false
    t.decimal "percentage", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_tax_brackets_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_tax_brackets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.jsonb "settings", default: {}, null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "addresses", "users"
  add_foreign_key "days", "days", column: "imported_from_day_id", on_delete: :nullify
  add_foreign_key "days", "days", column: "imported_to_day_id", on_delete: :nullify
  add_foreign_key "days", "users"
  add_foreign_key "items", "descendants"
  add_foreign_key "items", "items", column: "recurring_next_item_id", on_delete: :nullify
  add_foreign_key "items", "items", column: "source_item_id", on_delete: :nullify
  add_foreign_key "items", "users"
  add_foreign_key "lists", "descendants"
  add_foreign_key "lists", "users"
  add_foreign_key "tax_brackets", "users"
end
