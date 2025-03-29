# frozen_string_literal: true

class ReleasesController < ApplicationController
  include InModel

  def show
    return render_404 if id.nil?

    teams = current_model.teams_for_release(release_id: id, from:, to:, team_name: team, city:)
    @release = ReleasePresenter.new(id:, teams:)

    all_teams_count = current_model.count_all_teams_in_release(release_id: id, team_name: team, city:)
    @paging = Paging.new(items_count: all_teams_count, from:, to:)

    @filtered = city.present? || team.present?

    @releases_in_dropdown = list_releases_for_dropdown
    @model_name = current_model.name
  end

  def clean_params
    params.permit(:model, :release_id, :from, :to, :team, :city)
  end

  def from
    @from ||= (clean_params[:from] || 1).to_i
  end

  def to
    @to ||= (clean_params[:to] || 100).to_i
  end

  def city
    @city ||= clean_params[:city]&.gsub("*", "")
  end

  def team
    @team ||= clean_params[:team]&.gsub("*", "")
  end

  def id
    @id ||= if clean_params[:release_id].to_i == 0
      current_model&.latest_release_id
    else
      clean_params[:release_id].to_i
    end
  end

  def list_releases_for_dropdown
    current_model.all_releases.map do |release|
      [
        I18n.l(release["date"].to_date),
        release_path(release_id: release["id"], team:, city:)
      ]
    end
  end
end
