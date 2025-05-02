# frozen_string_literal: true

class AllRatingTournamentResultsJob < ApplicationJob
  queue_as :wrappers

  def perform
    single_tournament_jobs = tournaments
      .map { |tournament_id| SingleTournamentResultsJob.new(tournament_id) }

    ActiveJob.perform_all_later(single_tournament_jobs)
  end

  def tournaments
    Tournament.where(end_datetime: Date.new(2021, 9, 9)..Time.zone.today).pluck(:id)
  end
end
