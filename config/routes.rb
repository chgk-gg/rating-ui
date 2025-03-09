# frozen_string_literal: true

require "sidekiq/web"

if Rails.env.production?
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))
  end
end

Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  get "reindex", to: "reindex#reindex"
  get "ping", to: "healthcheck#ping"
  get "reset_cache", to: "cache#reset"
  get "recreate_views/:model", to: "materialized_views#recreate_views"
  get "recalculate_truedl/:model", to: "true_dls#recalculate"
  get "mau", to: "reports#mau"
  get "rules", to: "rules#index"

  get ":model/tournaments/", to: "tournaments#index", as: "tournaments"
  get ":model/tournament/:tournament_id", to: "tournaments#show", as: "tournament"
  get ":model/team/:team_id", to: "teams#show", as: "team"
  get ":model/player/:player_id", to: "players#show", as: "player"
  get ":model/players(/:release_id)", to: "player_releases#show", as: "player_release"
  get ":model(/:release_id)", to: "releases#show", as: "release"
  get ":model/tournament_rating_predictions/:tournament_id", to: "rating_predictions#show"

  namespace :api do
    namespace :v1 do
      get ":model/teams/:release_id", to: "teams#release"
      get ":model/teams/:team_id/releases", to: "teams#show"
      get ":model/players/:release_id", to: "players#release"
      get ":model/players/:player_id/releases", to: "players#show"
      get ":model/tournaments/:tournament_id", to: "tournaments#show"
      get ":model/releases", to: "releases#index"
      get ":model/wrong_team_ids", to: "wrong_team_ids#index"
    end
  end

  root to: "releases#show", model: InModel::DEFAULT_MODEL
end
