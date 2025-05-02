require_relative "../lib/truedl_calculator"

class TrueDLForAllTournamentsJob < ApplicationJob
  queue_as :wrappers

  def perform(model_name)
    model = Model.find_by(name: model_name)
    unless model
      Rails.logger.error "no model with the name #{model_name}"
      return
    end

    tournaments = Tournament.where("start_datetime >= '2021-09-01'").pluck(:id)
    single_tournament_jobs = tournaments.map do |tournament_id|
      TrueDLForTournamentJob.new(model_name, tournament_id)
    end

    ActiveJob.perform_all_later(single_tournament_jobs)
  end
end
