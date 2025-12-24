# frozen_string_literal: true

class PlayersController < ApplicationController
  include InModel

  def show
    player_id = params[:player_id].to_i
    @player = Player.find(player_id)
    @model_name = current_model.name

    releases = current_model.player_releases(player_id:)
    @releases_detailed = current_model.player_rating_components(player_id:)
    tournaments = current_model.player_tournaments(player_id:)
    @rows = ReleaseTournamentBuilder.build(releases, tournaments, {})
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def old_tournaments
    player_id = params[:player_id].to_i
    @player = Player.find(player_id)
    @model_name = current_model.name
    @old_tournaments = current_model.player_old_tournaments(player_id:)
    render partial: "old_tournaments_frame", layout: false
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
