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

ActiveRecord::Schema[7.0].define(version: 2026_11_05_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

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

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "countries", force: :cascade do |t|
    t.string "code", null: false
    t.string "title"
    t.string "title_ru"
    t.string "flag"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
    t.index ["position"], name: "index_countries_on_position"
  end

  create_table "hotels", force: :cascade do |t|
    t.string "name", null: false
    t.string "name_ru"
    t.string "city"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address_ru"
    t.string "phone"
    t.index ["city"], name: "index_hotels_on_city"
    t.index ["name"], name: "index_hotels_on_name"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "tariff"
    t.string "package"
    t.string "surname"
    t.string "name"
    t.string "middlename"
    t.string "sex"
    t.string "citizenship"
    t.string "birthDate"
    t.string "arival_date"
    t.string "departure_date"
    t.string "passport"
    t.text "visa_obtain_place"
    t.text "cities"
    t.text "hotels"
    t.text "hotels_ru"
    t.string "offname"
    t.string "email"
    t.string "website"
    t.string "promocode"
    t.text "comments"
    t.text "currency"
    t.float "price"
    t.string "accomodation"
    t.string "meals"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "purpose", default: "tourism", null: false
    t.string "status", default: "in_progress", null: false
    t.text "additional_info"
    t.integer "seal_left"
    t.integer "seal_right"
    t.string "verify_token"
    t.string "invitation_number"
    t.boolean "agency", default: false, null: false
    t.boolean "seal_high", default: false, null: false
    t.boolean "print_seal", default: true, null: false
    t.text "cancel_reason"
    t.jsonb "offers", default: [], null: false
    t.jsonb "offers_sent", default: [], null: false
    t.datetime "offers_sent_at"
    t.datetime "done_at"
    t.datetime "reminder_sent_at"
    t.index ["agency"], name: "index_invitations_on_agency"
    t.index ["done_at"], name: "index_invitations_on_done_at"
    t.index ["invitation_number"], name: "index_invitations_on_invitation_number", unique: true
    t.index ["status"], name: "index_invitations_on_status"
    t.index ["verify_token"], name: "index_invitations_on_verify_token", unique: true
  end

  create_table "service_requests", force: :cascade do |t|
    t.string "kind", null: false
    t.string "status", default: "new", null: false
    t.string "full_name"
    t.string "email", null: false
    t.string "phone"
    t.string "citizenship"
    t.string "passport_number"
    t.date "date_from"
    t.date "date_to"
    t.decimal "price", precision: 10, scale: 2
    t.string "currency", default: "usd", null: false
    t.jsonb "details", default: {}, null: false
    t.jsonb "checklist", default: {}, null: false
    t.text "comments"
    t.text "manager_notes"
    t.bigint "invitation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_service_requests_on_created_at"
    t.index ["invitation_id"], name: "index_service_requests_on_invitation_id"
    t.index ["kind"], name: "index_service_requests_on_kind"
    t.index ["status"], name: "index_service_requests_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "service_requests", "invitations"
end
