# frozen_string_literal: true

class RecentTournamentResultsJob < ApplicationJob
  queue_as :wrappers

  def perform(days)
    single_tournament_jobs = recent_tournaments(days)
      .map { |tournament_id| SingleTournamentResultsJob.new(tournament_id) }

    ActiveJob.perform_all_later(single_tournament_jobs)
  end

  def recent_tournaments(days)
    Tournament.where(end_datetime: (Time.zone.today - days)..Time.zone.today).pluck(:id)
  end
end
