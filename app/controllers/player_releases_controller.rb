# frozen_string_literal: true

class PlayerReleasesController < ApplicationController
  include InModel

  def show
    @release_id = clean_params[:release_id] || current_model.latest_release_id
    @releases_in_dropdown = list_releases_for_dropdown

    @players = current_model.players_for_release(release_id: @release_id, from:, to:, first_name:, last_name:)
    @filtered = first_name.present? || last_name.present?
    @paging = Paging.new(items_count: all_players_count, from:, to:)

    @model_name = current_model.name
  end

  def clean_params
    params.permit(:model, :release_id, :from, :to, :first_name, :last_name)
  end

  def from
    (clean_params[:from] || 1).to_i
  end

  def to
    (clean_params[:to] || 250).to_i
  end

  def first_name
    @first_name ||= clean_params[:first_name]&.gsub("*", "")
  end

  def last_name
    @last_name ||= clean_params[:last_name]&.gsub("*", "")
  end

  def all_players_count
    if @filtered
      current_model.count_all_players_in_release_with_filters(release_id: @release_id, first_name:, last_name:)
    else
      current_model.count_all_players_in_release(release_id: @release_id)
    end
  end

  def list_releases_for_dropdown
    current_model.all_releases.map do |release|
      [
        I18n.l(release["date"].to_date),
        player_release_path(release_id: release["id"])
      ]
    end
  end
end
