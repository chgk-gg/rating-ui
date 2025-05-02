# frozen_string_literal: true

class SingleTournamentResultsJob < ApplicationJob
  queue_as :chgk_info_import
  limits_concurrency to: 1, key: :chgk_info_api

  attr_reader :tournament_id, :api_client

  def perform(tournament_id)
    @tournament_id = tournament_id
    @api_client = ChgkInfo::APIClient.new

    update_rosters
    update_results
  end

  def update_rosters
    rosters_response = api_client.tournament_rosters(tournament_id:)
    flattened_rosters = flatten_rosters(rosters_response)
    ActiveRecord::Base.transaction do
      TournamentRoster.where(tournament_id:).delete_all
      TournamentRoster.insert_all(flattened_rosters, unique_by: %i[tournament_id team_id player_id])
    end
  end

  def flatten_rosters(rosters)
    rosters.flat_map do |roster|
      flatten_team_roster(roster)
    end.compact
  end

  def flatten_team_roster(team)
    return unless team.is_a? Hash

    team_id = team.dig("team", "id")
    team.fetch("teamMembers", []).map do |player|
      {
        team_id:,
        tournament_id:,
        player_id: player.dig("player", "id"),
        flag: player["flag"],
        is_captain: nil
      }
    end
  end

  def update_results
    results = api_client.tournament_results(tournament_id:)
    flattened_results = flatten_results(results)
    ActiveRecord::Base.transaction do
      TournamentResult.where(tournament_id:).delete_all
      TournamentResult.insert_all(flattened_results, unique_by: %i[tournament_id team_id])
    end
  end

  def flatten_results(results)
    return if results.is_a?(String)

    results.flat_map do |team|
      next unless team.is_a? Hash

      {
        tournament_id:,
        team_id: team.dig("team", "id"),
        team_title: team.dig("current", "name"),
        team_city_id: team.dig("current", "town", "id"),
        total: team["questionsTotal"],
        position: team["position"],
        old_rating: team.dig("rating", "b"),
        old_rating_delta: team.dig("rating", "d"),
        points: team["questionsTotal"],
        points_mask: team["mask"]
      }
    end.compact
  end
end
