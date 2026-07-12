class FetchAndRecalculateRecentJob < ApplicationJob
  WEEKS = 2
  POLL_INTERVAL = 15
  MAX_WAIT = 1.hour

  queue_as :wrappers
  queue_with_priority HIGH_PRIORITY

  def perform
    RecentTournamentResultsJob.perform_now(WEEKS * 7)
    wait_for_fetches
    RatingCalculationJob.perform_later(weeks: WEEKS)
  end

  private

  def wait_for_fetches
    deadline = Time.current + MAX_WAIT

    while fetches_pending?
      raise "tournament fetches still pending after #{MAX_WAIT.inspect}" if Time.current >= deadline

      Rails.logger.info "SingleTournamentResultsJob pending, will recheck in #{POLL_INTERVAL} seconds"
      sleep POLL_INTERVAL
    end
  end

  def fetches_pending?
    SolidQueue::Job
      .where(class_name: SingleTournamentResultsJob.name, finished_at: nil)
      .where.not(id: SolidQueue::FailedExecution.select(:job_id))
      .exists?
  end
end
