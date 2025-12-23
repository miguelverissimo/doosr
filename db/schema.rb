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

ActiveRecord::Schema[8.1].define(version: 2025_12_23_063846) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounting_items", force: :cascade do |t|
    t.boolean "convert_currency", default: false, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.string "description"
    t.string "detail"
    t.string "kind", null: false
    t.string "name", null: false
    t.integer "price", null: false
    t.string "reference", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_accounting_items_on_user_id"
  end

  create_table "accounting_logos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_accounting_logos_on_user_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "checklists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "flow", default: "sequential", null: false
    t.jsonb "items", default: []
    t.string "kind", default: "template", null: false
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.bigint "template_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["flow"], name: "index_checklists_on_flow"
    t.index ["items"], name: "index_checklists_on_items", using: :gin
    t.index ["kind"], name: "index_checklists_on_kind"
    t.index ["template_id"], name: "index_checklists_on_template_id"
    t.index ["user_id"], name: "index_checklists_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.string "billing_contact_name"
    t.string "billing_email"
    t.string "billing_phone"
    t.string "contact_email"
    t.string "contact_name"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.json "metadata"
    t.string "name", null: false
    t.text "notes"
    t.string "telephone"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["address_id"], name: "index_customers_on_address_id"
    t.index ["user_id"], name: "index_customers_on_user_id"
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

  create_table "fiscal_infos", force: :cascade do |t|
    t.bigint "address_id"
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.string "tax_number"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["address_id"], name: "index_fiscal_infos_on_address_id"
    t.index ["user_id"], name: "index_fiscal_infos_on_user_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.integer "amount"
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "discount_amount"
    t.float "discount_rate"
    t.boolean "display_quantity"
    t.bigint "invoice_id", null: false
    t.bigint "item_id", null: false
    t.float "quantity"
    t.integer "subtotal"
    t.integer "tax_amount"
    t.bigint "tax_bracket_id", null: false
    t.string "tax_exemption_motive"
    t.float "tax_rate"
    t.string "unit"
    t.integer "unit_price"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["item_id"], name: "index_invoice_items_on_item_id"
    t.index ["tax_bracket_id"], name: "index_invoice_items_on_tax_bracket_id"
    t.index ["user_id"], name: "index_invoice_items_on_user_id"
  end

  create_table "invoice_templates", force: :cascade do |t|
    t.bigint "accounting_logo_id", null: false
    t.datetime "created_at", null: false
    t.string "currency"
    t.bigint "customer_id", null: false
    t.string "description"
    t.string "name"
    t.bigint "provider_address_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["accounting_logo_id"], name: "index_invoice_templates_on_accounting_logo_id"
    t.index ["customer_id"], name: "index_invoice_templates_on_customer_id"
    t.index ["provider_address_id"], name: "index_invoice_templates_on_provider_address_id"
    t.index ["user_id"], name: "index_invoice_templates_on_user_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.bigint "customer_id", null: false
    t.integer "discount"
    t.string "display_number", null: false
    t.datetime "due_at"
    t.bigint "invoice_template_id"
    t.datetime "issued_at"
    t.jsonb "metadata"
    t.text "notes"
    t.integer "number", null: false
    t.bigint "provider_id", null: false
    t.string "state", default: "draft", null: false
    t.integer "subtotal"
    t.integer "tax"
    t.integer "total"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "year", null: false
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["invoice_template_id"], name: "index_invoices_on_invoice_template_id"
    t.index ["provider_id"], name: "index_invoices_on_provider_id"
    t.index ["user_id", "display_number"], name: "index_invoices_on_user_id_and_display_number", unique: true
    t.index ["user_id", "state"], name: "index_invoices_on_user_id_and_state"
    t.index ["user_id", "year", "number"], name: "index_invoices_on_user_id_and_year_and_number", unique: true
    t.index ["user_id"], name: "index_invoices_on_user_id"
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

  add_foreign_key "accounting_items", "users"
  add_foreign_key "accounting_logos", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "users"
  add_foreign_key "checklists", "checklists", column: "template_id", on_delete: :nullify
  add_foreign_key "checklists", "users"
  add_foreign_key "customers", "addresses"
  add_foreign_key "customers", "users"
  add_foreign_key "days", "days", column: "imported_from_day_id", on_delete: :nullify
  add_foreign_key "days", "days", column: "imported_to_day_id", on_delete: :nullify
  add_foreign_key "days", "users"
  add_foreign_key "fiscal_infos", "addresses"
  add_foreign_key "fiscal_infos", "users"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_items", "items"
  add_foreign_key "invoice_items", "tax_brackets"
  add_foreign_key "invoice_items", "users"
  add_foreign_key "invoice_templates", "accounting_logos"
  add_foreign_key "invoice_templates", "addresses", column: "provider_address_id"
  add_foreign_key "invoice_templates", "customers"
  add_foreign_key "invoice_templates", "users"
  add_foreign_key "invoices", "addresses", column: "provider_id"
  add_foreign_key "invoices", "customers"
  add_foreign_key "invoices", "invoice_templates"
  add_foreign_key "invoices", "users"
  add_foreign_key "items", "descendants"
  add_foreign_key "items", "items", column: "recurring_next_item_id", on_delete: :nullify
  add_foreign_key "items", "items", column: "source_item_id", on_delete: :nullify
  add_foreign_key "items", "users"
  add_foreign_key "lists", "descendants"
  add_foreign_key "lists", "users"
  add_foreign_key "tax_brackets", "users"
end
