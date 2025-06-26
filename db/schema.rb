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

ActiveRecord::Schema[8.0].define(version: 2025_06_26_060428) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "billing_configs", force: :cascade do |t|
    t.integer "generation_months_ahead", default: 3, null: false
    t.integer "archiving_months_threshold", default: 6, null: false
    t.integer "due_soon_days", default: 7, null: false
    t.boolean "auto_archiving_enabled", default: true, null: false
    t.boolean "auto_generation_enabled", default: true, null: false
    t.text "default_billing_frequencies", default: "[\"monthly\"]"
    t.text "supported_billing_frequencies", default: "[\"monthly\", \"quarterly\", \"yearly\"]"
    t.text "reminder_schedule", default: "[7, 3, 1]"
    t.integer "payment_grace_period_days", default: 5, null: false
    t.boolean "reminders_enabled", default: true, null: false
    t.integer "gentle_reminder_days_before", default: 3, null: false
    t.integer "standard_reminder_days_overdue", default: 1, null: false
    t.integer "urgent_reminder_days_overdue", default: 7, null: false
    t.integer "final_notice_days_overdue", default: 14, null: false
    t.string "default_frequency", default: "monthly", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "archiving_months_threshold > 0 AND archiving_months_threshold <= 24", name: "archiving_months_threshold_range"
    t.check_constraint "default_frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')", name: "default_frequency_valid"
    t.check_constraint "due_soon_days > 0 AND due_soon_days <= 30", name: "due_soon_days_range"
    t.check_constraint "final_notice_days_overdue >= 0 AND final_notice_days_overdue <= 90", name: "final_notice_days_range"
    t.check_constraint "generation_months_ahead > 0 AND generation_months_ahead <= 12", name: "generation_months_ahead_range"
    t.check_constraint "gentle_reminder_days_before > 0 AND gentle_reminder_days_before <= 30", name: "gentle_reminder_days_range"
    t.check_constraint "payment_grace_period_days >= 0 AND payment_grace_period_days <= 30", name: "payment_grace_period_range"
    t.check_constraint "standard_reminder_days_overdue >= 0 AND standard_reminder_days_overdue <= 30", name: "standard_reminder_days_range"
    t.check_constraint "urgent_reminder_days_overdue >= 0 AND urgent_reminder_days_overdue <= 60", name: "urgent_reminder_days_range"
  end

  create_table "billing_cycles", force: :cascade do |t|
    t.integer "project_id", null: false
    t.date "due_date"
    t.decimal "total_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false, null: false
    t.datetime "archived_at"
    t.text "adjustment_reason"
    t.datetime "adjusted_at"
    t.decimal "original_amount"
    t.date "original_due_date"
    t.index ["adjusted_at"], name: "index_billing_cycles_on_adjusted_at"
    t.index ["archived"], name: "index_billing_cycles_on_archived"
    t.index ["archived_at"], name: "index_billing_cycles_on_archived_at"
    t.index ["due_date"], name: "index_billing_cycles_on_due_date"
    t.index ["project_id", "due_date"], name: "index_billing_cycles_on_project_id_and_due_date"
    t.index ["project_id"], name: "index_billing_cycles_on_project_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "email"
    t.string "token", null: false
    t.string "status", default: "pending", null: false
    t.integer "invited_by_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["expires_at"], name: "index_invitations_on_expires_at"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["project_id", "email"], name: "index_invitations_on_project_id_and_email", unique: true, where: "email IS NOT NULL"
    t.index ["project_id"], name: "index_invitations_on_project_id"
    t.index ["status"], name: "index_invitations_on_status"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "magic_links", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token"
    t.datetime "expires_at"
    t.boolean "used", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_magic_links_on_expires_at"
    t.index ["token", "expires_at", "used"], name: "index_magic_links_for_validation"
    t.index ["token"], name: "index_magic_links_on_token", unique: true
    t.index ["user_id", "used"], name: "index_magic_links_on_user_id_and_used"
    t.index ["user_id"], name: "index_magic_links_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "billing_cycle_id", null: false
    t.integer "user_id", null: false
    t.decimal "amount"
    t.string "status"
    t.date "confirmation_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_id"
    t.text "notes"
    t.text "confirmation_notes"
    t.bigint "confirmed_by_id"
    t.boolean "disputed", default: false
    t.text "dispute_reason"
    t.datetime "dispute_resolved_at"
    t.json "status_history", default: []
    t.index ["billing_cycle_id", "user_id"], name: "index_payments_on_billing_cycle_id_and_user_id", unique: true
    t.index ["billing_cycle_id"], name: "index_payments_on_billing_cycle_id"
    t.index ["confirmed_by_id"], name: "index_payments_on_confirmed_by_id"
    t.index ["disputed"], name: "index_payments_on_disputed"
    t.index ["status", "confirmation_date"], name: "index_payments_on_status_and_confirmation_date"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "project_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "project_id", null: false
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_memberships_on_project_id"
    t.index ["role"], name: "index_project_memberships_on_role"
    t.index ["user_id", "project_id"], name: "index_project_memberships_on_user_id_and_project_id", unique: true
    t.index ["user_id"], name: "index_project_memberships_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.decimal "cost"
    t.string "billing_cycle"
    t.date "renewal_date"
    t.text "payment_instructions"
    t.integer "reminder_days"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "subscription_url"
    t.string "slug", null: false
    t.string "currency", default: "USD", null: false
    t.index ["billing_cycle"], name: "index_projects_on_billing_cycle"
    t.index ["currency"], name: "index_projects_on_currency"
    t.index ["renewal_date"], name: "index_projects_on_renewal_date"
    t.index ["slug"], name: "index_projects_on_slug", unique: true
    t.index ["user_id", "renewal_date"], name: "index_projects_on_user_id_and_renewal_date"
    t.index ["user_id"], name: "index_projects_on_user_id"
    t.check_constraint "currency IN ('USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CHF', 'CNY', 'INR', 'BRL', 'MXN', 'KRW', 'SGD', 'HKD', 'NZD', 'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'BGN', 'RON', 'HRK', 'RUB', 'TRY', 'ZAR', 'THB', 'MYR', 'IDR', 'PHP', 'VND')", name: "projects_currency_valid"
  end

  create_table "reminder_schedules", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "days_before"
    t.integer "escalation_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["days_before"], name: "index_reminder_schedules_on_days_before"
    t.index ["project_id", "escalation_level"], name: "index_reminder_schedules_on_project_id_and_escalation_level"
    t.index ["project_id"], name: "index_reminder_schedules_on_project_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "preferences"
    t.string "first_name"
    t.string "last_name"
    t.string "preferred_currency", default: "USD", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["preferred_currency"], name: "index_users_on_preferred_currency"
    t.check_constraint "preferred_currency IN ('USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CHF', 'CNY', 'INR', 'BRL', 'MXN', 'KRW', 'SGD', 'HKD', 'NZD', 'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'BGN', 'RON', 'HRK', 'RUB', 'TRY', 'ZAR', 'THB', 'MYR', 'IDR', 'PHP', 'VND')", name: "users_preferred_currency_valid"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "billing_cycles", "projects"
  add_foreign_key "invitations", "projects"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "magic_links", "users"
  add_foreign_key "payments", "billing_cycles"
  add_foreign_key "payments", "users"
  add_foreign_key "payments", "users", column: "confirmed_by_id"
  add_foreign_key "project_memberships", "projects"
  add_foreign_key "project_memberships", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "reminder_schedules", "projects"
  add_foreign_key "sessions", "users"
end
