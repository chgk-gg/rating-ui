# frozen_string_literal: true

class TournamentsController < ApplicationController
  include InModel

  TOURNAMENT_TYPES = {
    6 => "Строго синхронный",
    3 => "Синхрон",
    5 => "Общий зачёт",
    8 => "Асинхрон",
    2 => "Обычный"
  }.freeze

  def index
    @tournament_name = tournament_name
    @type_id = type_id
    @tournaments = current_model.tournaments_list(from:, to:, name_filter: @tournament_name, type_id: @type_id)
    @true_dls = TrueDl.where(model: current_model, tournament_id: @tournaments.map(&:id))
      .group(:tournament_id)
      .average(:true_dl)
      .to_h

    @paging = Paging.new(items_count: all_tournaments_count, from:, to:)
    @filtered = @tournament_name.present? || @type_id.present?
    @tournament_types = TOURNAMENT_TYPES
  end

  def show
    id = params[:tournament_id].to_i
    tournament = Tournament.find(id)

    results = current_model.tournament_results(tournament_id: id)

    all_players = tournament.players_with_names.group_by(&:team_id)
    results.each { |tr| tr.players = all_players[tr["team_id"]] }

    true_dls_by_team = TrueDLCalculator.tournament_dl_by_team(tournament_id: id, model: current_model)
    @true_dl = true_dls_by_team.values.sum / true_dls_by_team.size.to_f unless true_dls_by_team.empty?

    @tournament = TournamentPresenter.new(id:, tournament:, results:, truedls: true_dls_by_team)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def clean_params
    params.permit(:model, :from, :to, :name, :type_id)
  end

  def from
    @from ||= (clean_params[:from] || 1).to_i
  end

  def to
    @to ||= (clean_params[:to] || 50).to_i
  end

  def tournament_name
    @tournament_name ||= clean_params[:name]&.gsub("*", "")
  end

  def type_id
    @type_id ||= clean_params[:type_id].presence
  end

  def all_tournaments_count
    current_model.count_all_tournaments(name_filter: tournament_name, type_id:)
  end
end
