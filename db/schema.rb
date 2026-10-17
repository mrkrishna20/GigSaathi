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

ActiveRecord::Schema[8.1].define(version: 2026_10_17_010000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "earnings", force: :cascade do |t|
    t.date "work_date", null: false
    t.decimal "total_earnings", precision: 10, scale: 2, null: false
    t.decimal "fuel_expenses", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "food_expenses", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "other_expenses", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id", "work_date", "created_at"], name: "index_earnings_on_user_and_workday", order: { work_date: :desc, created_at: :desc }
    t.index ["work_date"], name: "index_earnings_on_work_date"
  end

  add_check_constraint "earnings", "user_id IS NOT NULL", name: "earnings_must_belong_to_a_user", validate: false

  create_table "users", force: :cascade do |t|
    t.string "email", limit: 254, null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
  end

  add_foreign_key "earnings", "users"
end
