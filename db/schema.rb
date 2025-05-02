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

ActiveRecord::Schema[8.0].define(version: 2025_05_02_111023) do
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
    t.date "date_died"
    t.integer "got_questions_tag"
    t.index ["id"], name: "index_players_on_id", unique: true
    t.index ["id"], name: "players_id_index"
  end

  create_table "seasons", id: false, force: :cascade do |t|
    t.integer "id"
    t.date "start"
    t.date "end"
    t.datetime "updated_at", precision: nil
    t.index ["id"], name: "index_seasons_on_id", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "teams", id: false, force: :cascade do |t|
    t.integer "id"
    t.text "title"
    t.integer "town_id"
    t.datetime "updated_at", precision: nil
    t.index ["id"], name: "index_teams_on_id", unique: true
  end

  create_table "tournament_appeal_jury", force: :cascade do |t|
    t.integer "tournament_id"
    t.integer "player_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id", "player_id"], name: "index_tournament_appeal_jury_on_tournament_id_and_player_id", unique: true
  end

  create_table "tournament_editors", force: :cascade do |t|
    t.integer "tournament_id"
    t.integer "player_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id", "player_id"], name: "index_tournament_editors_on_tournament_id_and_player_id", unique: true
  end

  create_table "tournament_game_jury", force: :cascade do |t|
    t.integer "tournament_id"
    t.integer "player_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id", "player_id"], name: "index_tournament_game_jury_on_tournament_id_and_player_id", unique: true
  end

  create_table "tournament_organizers", force: :cascade do |t|
    t.integer "tournament_id"
    t.integer "player_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id", "player_id"], name: "index_tournament_organizers_on_tournament_id_and_player_id", unique: true
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
    t.index ["id"], name: "index_towns_on_id", unique: true
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

  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "true_dls", "models"
end
