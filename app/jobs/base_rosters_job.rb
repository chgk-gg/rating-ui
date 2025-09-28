# frozen_string_literal: true

require "active_job/continuable"

class BaseRostersJob < ApplicationJob
  include ActiveJob::Continuable

  queue_as :chgk_info_import
  limits_concurrency to: 1, key: :chgk_info_api

  def perform(teams_category)
    raise ArgumentError unless %w[all from_rating_tournaments].include?(teams_category)

    team_ids = if teams_category == "from_rating_tournaments"
      teams_from_rating_tournaments
    else
      (1..find_max_team_id).to_a
    end

    @api_client = ChgkInfo::APIClient.new

    step :fetch_rosters, start: 0 do |step|
      team_ids[step.cursor..].each do |team_id|
        rosters = @api_client.team_rosters(team_id:)
        next if rosters.empty?

        roster_rows = rosters.map do
          {
            team_id: it["idteam"],
            player_id: it["idplayer"],
            season_id: it["idseason"],
            start_date: it["dateAdded"],
            end_date: it["dateRemoved"]
          }
        end

        ActiveRecord::Base.transaction do
          BaseRoster.upsert_all(roster_rows, unique_by: %i[team_id player_id season_id])
        end

        step.advance!
        sleep Random.rand(1.0)
      end
    end
  end

  def teams_from_rating_tournaments
    Tournament.where(maii_rating: true)
      .joins(:tournament_results)
      .distinct
      .pluck("tournament_results.team_id")
      .sort
  end

  def find_max_team_id
    # Allowing for 100 new teams compared to what we already have
    Team.maximum(:id) + 100
  end
end
