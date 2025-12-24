# frozen_string_literal: true

class TeamsController < ApplicationController
  include InModel

  def show
    team_id = params[:team_id].to_i
    @team = Team.team_details_by_id(team_id)
    return render_404 if @team.nil?

    @model_name = current_model.name
    releases = current_model.team_releases(team_id:)
    tournaments = current_model.team_tournaments(team_id:)

    @all_players = Team.players_in_all_tournaments(team_id)

    @rows = ReleaseTournamentBuilder.build(releases, tournaments, @all_players)
    @current_season = Season.current_season

    @base_roster = @team.base_roster_for_season(@current_season.id)
  end

  def old_tournaments
    team_id = params[:team_id].to_i
    @team = Team.team_details_by_id(team_id)
    return render_404 if @team.nil?

    @model_name = current_model.name
    @all_players = Team.players_in_all_tournaments(team_id)
    @old_tournaments = Tournament.pre_maii_tournaments_for_team(team_id).map(&:attributes)
    @old_tournaments.each { |t| t["players"] = @all_players[t["id"]] }
    render partial: "old_tournaments_frame", layout: false
  end
end
