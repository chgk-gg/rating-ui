# frozen_string_literal: true

class RecentTournamentResultsJob < ApplicationJob
  queue_as :wrappers

  def perform(days)
    single_tournament_jobs = recent_tournaments(days)
      .map { |tournament_id| SingleTournamentResultsJob.new(tournament_id) }

    ActiveJob.perform_all_later(single_tournament_jobs)
  end

  def recent_tournaments(days)
    # This style of `where` generates a `between 'earliest' and 'latest'` SQL query,
    # with `'latest'` not being included. That’s why we add one more day.
    earliest = Time.zone.today - days
    latest = Time.zone.today + 1.day
    Tournament.where(end_datetime: earliest..latest).pluck(:id)
  end
end
