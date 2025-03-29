# frozen_string_literal: true

class TrueDLCalculator
  TrueDLInput = Data.define(:teams, :questions_count)

  def self.tournament_dl(tournament_id:, model:)
    TrueDl.where(model:, tournament_id:).average(:true_dl)
  end

  def self.tournament_dl_by_team(tournament_id:, model:)
    TrueDl.where(model:, tournament_id:).pluck(:team_id, :true_dl).to_h
  end

  def self.calculate_for_tournament(tournament_id:, model_name:)
    TrueDLCalculator.new(tournament_id, model_name).run
  end

  attr_reader :tournament_id, :model

  def initialize(tournament_id, model_name)
    @model = Model.find_by(name: model_name)
    @tournament_id = tournament_id
  end

  def tournament
    @tournament ||= Tournament.find(tournament_id)
  end

  def date
    @date ||= tournament.start_datetime
  end

  def tournament_results
    @tournament_results ||= model.tournament_results(tournament_id:)
  end

  def run
    unless model
      Rails.logger.info "no model with the name #{model_name}"
      return
    end

    true_dl_input = fetch_data_for_true_dl
    return unless true_dl_input

    dl_values = TrueDL.true_dls_for_tournament(teams: true_dl_input.teams,
      number_of_questions: true_dl_input.questions_count)
    return if dl_values.blank?

    save_to_database(dl_values)
  end

  private

  def save_to_database(dl_values)
    upsert_entries = dl_values.map do |dl_value|
      {model_id: model.id, tournament_id:, team_id: dl_value.id, true_dl: dl_value.dl}
    end

    TrueDl.upsert_all(upsert_entries, unique_by: %i[model_id tournament_id team_id]) # rubocop:disable Rails/SkipsModelValidations
  end

  def fetch_data_for_true_dl
    return if tournament.questions_count.blank?
    return if tournament_results_invalid?

    filter_by_continuity!
    return if tournament_results.empty?

    rankings = model.teams_ranking(team_ids: tournament_results.map(&:team_id), date:)
    return if rankings.blank?

    teams = join_results_and_rankings(rankings)

    TrueDLInput[teams:, questions_count: tournament.questions_count]
  end

  def filter_by_continuity!
    team_ids = tournament_results.map(&:team_id)
    tournament_rosters = model.tournament_players(tournament_id:)
    base_rosters = model.base_rosters_on_date(team_ids:, date:).pluck("player_id", "team_id")

    team_ids.each do |team_id|
      players = tournament_rosters[team_id].pluck("player_id")
      base_players = base_rosters.filter { |_, roster_id| roster_id == team_id }.map(&:first)
      next if RosterContinuity.has_continuity?(players:, base_players:, date:)

      tournament_results.delete_if { |result| result.team_id == team_id }
    end
  end

  def join_results_and_rankings(rankings)
    tournament_results.map do |result|
      next if rankings[result.team_id].blank?

      {id: result.team_id, points: result.points, ranking: rankings[result.team_id].first["place"]}
    end.compact
  end

  def tournament_results_invalid?
    return true if tournament_results.blank?

    places = tournament_results.map(&:place)
    return true if places.compact.empty?
    return true if places.min >= 9999

    false
  end
end
