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

ActiveRecord::Schema[7.2].define(version: 2024_11_24_122023) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "base_rosters", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.integer "player_id"
    t.integer "team_id"
    t.integer "season_id"
    t.date "start_date"
    t.date "end_date"
    t.datetime "updated_at", precision: nil
    t.index ["player_id"], name: "base_rosters_player_id_index"
    t.index ["team_id"], name: "base_rosters_team_id_index"
  end

  create_table "models", force: :cascade do |t|
    t.text "name"
    t.boolean "changes_teams"
    t.boolean "changes_rosters"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["name"], name: "index_models_on_name", unique: true
  end

  create_table "players", id: false, force: :cascade do |t|
    t.integer "id"
    t.text "first_name"
    t.text "patronymic"
    t.text "last_name"
    t.datetime "updated_at", precision: nil
    t.index ["id"], name: "players_id_index"
  end

  create_table "seasons", id: false, force: :cascade do |t|
    t.integer "id"
    t.date "start"
    t.date "end"
    t.datetime "updated_at", precision: nil
  end

  create_table "teams", id: false, force: :cascade do |t|
    t.integer "id"
    t.text "title"
    t.integer "town_id"
    t.datetime "updated_at", precision: nil
  end

  create_table "tournament_results", id: false, force: :cascade do |t|
    t.bigserial "id", null: false
    t.integer "tournament_id"
    t.integer "team_id"
    t.text "team_title"
    t.integer "total"
    t.float "position"
    t.integer "old_rating"
    t.integer "old_rating_delta"
    t.datetime "updated_at", precision: nil
    t.integer "team_city_id"
    t.integer "points"
    t.text "points_mask"
    t.index ["team_id", "tournament_id"], name: "index_tournament_results_on_team_id_and_tournament_id", unique: true
    t.index ["team_id"], name: "tournament_results_team_id_index"
    t.index ["tournament_id"], name: "tournament_results_tournament_id_index"
  end

  create_table "tournament_rosters", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.integer "tournament_id"
    t.integer "team_id"
    t.integer "player_id"
    t.text "flag"
    t.boolean "is_captain"
    t.datetime "updated_at", precision: nil
    t.index ["player_id", "tournament_id", "team_id"], name: "tournament_rosters_uindex", unique: true
    t.index ["player_id"], name: "tournaments_roster_player_id_index"
    t.index ["team_id", "tournament_id"], name: "tournament_rosters_team_id_tournament_id_index"
    t.index ["tournament_id"], name: "tournaments_roster_tournament_id_index"
  end

  create_table "tournaments", id: false, force: :cascade do |t|
    t.integer "id"
    t.text "title"
    t.datetime "start_datetime", precision: nil
    t.datetime "end_datetime", precision: nil
    t.datetime "last_edited_at", precision: nil
    t.integer "questions_count"
    t.integer "typeoft_id"
    t.text "type"
    t.boolean "maii_rating"
    t.datetime "maii_rating_updated_at", precision: nil
    t.boolean "maii_aegis"
    t.datetime "maii_aegis_updated_at", precision: nil
    t.boolean "in_old_rating"
    t.datetime "updated_at", precision: nil
    t.index ["end_datetime"], name: "tournaments_end_datetime_index", order: :desc
    t.index ["id"], name: "tournaments_id_index"
    t.index ["start_datetime"], name: "tournaments_start_datetime_index", order: :desc
    t.index ["type"], name: "tournaments_type_index"
  end

  create_table "towns", id: false, force: :cascade do |t|
    t.integer "id"
    t.text "title"
    t.datetime "updated_at", precision: nil
  end

  create_table "true_dls", force: :cascade do |t|
    t.bigint "id"
    t.integer "tournament_id"
    t.float "true_dl"
    t.bigint "model_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "team_id"
    t.index ["model_id", "team_id", "tournament_id"], name: "index_true_dls_on_model_id_and_team_id_and_tournament_id", unique: true
    t.index ["model_id"], name: "index_true_dls_on_model_id"
  end

  create_table "wrong_team_ids", force: :cascade do |t|
    t.integer "tournament_id"
    t.integer "old_team_id"
    t.integer "new_team_id"
    t.datetime "updated_at"
  end

  add_foreign_key "true_dls", "models"
end
