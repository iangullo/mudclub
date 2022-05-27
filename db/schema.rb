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

ActiveRecord::Schema[7.0].define(version: 2022_05_25_060105) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
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

  create_table "categories", force: :cascade do |t|
    t.string "age_group"
    t.string "sex"
    t.integer "min_years"
    t.integer "max_years"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "coaches", force: :cascade do |t|
    t.boolean "active"
    t.bigint "person_id", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_coaches_on_person_id"
  end

  create_table "coaches_teams", id: false, force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "coach_id", null: false
  end

  create_table "divisions", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "drill_targets", force: :cascade do |t|
    t.integer "priority"
    t.bigint "target_id", null: false
    t.bigint "drill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["drill_id"], name: "index_drill_targets_on_drill_id"
    t.index ["target_id"], name: "index_drill_targets_on_target_id"
  end

  create_table "drills", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "material"
    t.bigint "coach_id", default: 0, null: false
    t.bigint "kind_id", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coach_id"], name: "index_drills_on_coach_id"
    t.index ["kind_id"], name: "index_drills_on_kind_id"
  end

  create_table "drills_skills", id: false, force: :cascade do |t|
    t.bigint "drill_id", null: false
    t.bigint "skill_id", null: false
  end

  create_table "event_targets", force: :cascade do |t|
    t.integer "priority"
    t.bigint "event_id", null: false
    t.bigint "target_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_targets_on_event_id"
    t.index ["target_id"], name: "index_event_targets_on_target_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "start_time", precision: nil
    t.integer "kind"
    t.bigint "team_id", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "end_time", precision: nil
    t.string "name"
    t.boolean "home", default: true
    t.index ["location_id"], name: "index_events_on_location_id"
    t.index ["team_id"], name: "index_events_on_team_id"
  end

  create_table "kinds", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_kinds_on_name"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.string "gmaps_url"
    t.boolean "practice_court"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "people", force: :cascade do |t|
    t.string "dni"
    t.string "nick"
    t.string "name"
    t.string "surname"
    t.date "birthday"
    t.boolean "female"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "player_id", default: 0, null: false
    t.bigint "coach_id", default: 0, null: false
    t.bigint "user_id", default: 0, null: false
    t.index ["coach_id"], name: "index_people_on_coach_id"
    t.index ["name"], name: "index_people_on_name"
    t.index ["player_id"], name: "index_people_on_player_id"
    t.index ["surname"], name: "index_people_on_surname"
    t.index ["user_id"], name: "index_people_on_user_id"
  end

  create_table "players", force: :cascade do |t|
    t.integer "number"
    t.boolean "active"
    t.bigint "person_id", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_players_on_person_id"
  end

  create_table "players_teams", id: false, force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "player_id", null: false
  end

  create_table "season_locations", force: :cascade do |t|
    t.bigint "season_id", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_season_locations_on_location_id"
    t.index ["season_id"], name: "index_season_locations_on_season_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "start_date"
    t.date "end_date"
  end

  create_table "skills", force: :cascade do |t|
    t.string "concept"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["concept"], name: "index_skills_on_concept"
  end

  create_table "slots", force: :cascade do |t|
    t.integer "wday"
    t.time "start"
    t.integer "duration"
    t.bigint "season_id", default: 0, null: false
    t.bigint "team_id", default: 0, null: false
    t.bigint "location_id", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_slots_on_location_id"
    t.index ["season_id"], name: "index_slots_on_season_id"
    t.index ["team_id"], name: "index_slots_on_team_id"
  end

  create_table "stats", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "player_id", null: false
    t.integer "concept"
    t.integer "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_stats_on_event_id"
    t.index ["player_id"], name: "index_stats_on_player_id"
  end

  create_table "targets", force: :cascade do |t|
    t.integer "focus"
    t.integer "aspect"
    t.string "concept"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["concept"], name: "index_targets_on_concept"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.integer "order"
    t.bigint "drill_id", null: false
    t.integer "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "remarks"
    t.index ["drill_id"], name: "index_tasks_on_drill_id"
    t.index ["event_id"], name: "index_tasks_on_event_id"
  end

  create_table "team_targets", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "target_id", null: false
    t.integer "priority"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "month"
    t.index ["target_id"], name: "index_team_targets_on_target_id"
    t.index ["team_id"], name: "index_team_targets_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.bigint "season_id", default: 0, null: false
    t.bigint "category_id", default: 0, null: false
    t.bigint "division_id", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "homecourt_id", default: 0
    t.index ["category_id"], name: "index_teams_on_category_id"
    t.index ["division_id"], name: "index_teams_on_division_id"
    t.index ["homecourt_id"], name: "index_teams_on_homecourt_id"
    t.index ["season_id"], name: "index_teams_on_season_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.bigint "person_id", default: 0, null: false
    t.integer "role", default: 0
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["person_id"], name: "index_users_on_person_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "coaches", "people"
  add_foreign_key "drill_targets", "drills"
  add_foreign_key "drill_targets", "targets"
  add_foreign_key "drills", "coaches"
  add_foreign_key "drills", "kinds"
  add_foreign_key "event_targets", "events"
  add_foreign_key "event_targets", "targets"
  add_foreign_key "events", "locations"
  add_foreign_key "events", "teams"
  add_foreign_key "people", "coaches"
  add_foreign_key "people", "players"
  add_foreign_key "people", "users"
  add_foreign_key "players", "people"
  add_foreign_key "season_locations", "locations"
  add_foreign_key "season_locations", "seasons"
  add_foreign_key "slots", "locations"
  add_foreign_key "slots", "seasons"
  add_foreign_key "slots", "teams"
  add_foreign_key "stats", "events"
  add_foreign_key "stats", "players"
  add_foreign_key "tasks", "drills"
  add_foreign_key "tasks", "events"
  add_foreign_key "team_targets", "targets"
  add_foreign_key "team_targets", "teams"
  add_foreign_key "teams", "categories"
  add_foreign_key "teams", "divisions"
  add_foreign_key "teams", "locations", column: "homecourt_id"
  add_foreign_key "teams", "seasons"
  add_foreign_key "users", "people"
end
