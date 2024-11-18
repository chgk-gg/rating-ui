# frozen_string_literal: true

class ReportsController < ActionController::Base
  include ReportsQueries

  def mau
    @active_rating_data = active_rating_players.map { |month| {x: month.month, y: month.players_count} }.to_json
    @all_time_rating_data = old_rating_players.map { |month| {x: month.month, y: month.players_count} }.to_json
    @all_time_data = all_players.map { |month| {x: month.month, y: month.players_count} }.to_json
    render layout: "nonmodel"
  end
end
