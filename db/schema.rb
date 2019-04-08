# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190322222838) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "copy_downs", force: :cascade do |t|
    t.string   "name"
    t.string   "company_id"
    t.string   "property_id"
    t.string   "rule_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "events", force: :cascade do |t|
    t.integer  "provision_id"
    t.json     "data"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["provision_id"], name: "index_events_on_provision_id", using: :btree
  end

  create_table "provisions", force: :cascade do |t|
    t.string   "company_name"
    t.string   "company_id"
    t.string   "property_name"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "target_rules", force: :cascade do |t|
    t.string   "rule_id"
    t.string   "company_id"
    t.string   "property_id"
    t.string   "name"
    t.integer  "copy_down_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["copy_down_id"], name: "index_target_rules_on_copy_down_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "email",                          null: false
    t.string   "encrypted_password", limit: 128, null: false
    t.string   "confirmation_token", limit: 128
    t.string   "remember_token",     limit: 128, null: false
    t.index ["email"], name: "index_users_on_email", using: :btree
    t.index ["remember_token"], name: "index_users_on_remember_token", using: :btree
  end

end
