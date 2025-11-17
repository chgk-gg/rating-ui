# frozen_string_literal: true

class RecentTournamentResultsJob < ApplicationJob
  queue_as :wrappers

  def perform(days)
    single_tournament_jobs = Tournament.recent_tournaments(days).pluck(:id)
      .map { |tournament_id| SingleTournamentResultsJob.new(tournament_id) }

    ActiveJob.perform_all_later(single_tournament_jobs)
  end
end
