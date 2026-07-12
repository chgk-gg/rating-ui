require "test_helper"

class FetchAndRecalculateRecentJobTest < ActiveSupport::TestCase
  def test_fetches_synchronously_then_enqueues_recalculation
    order = sequence("fetch, then recalculate")
    RecentTournamentResultsJob.expects(:perform_now).with(14).in_sequence(order)
    RatingCalculationJob.expects(:perform_later).with(weeks: 2).in_sequence(order)

    FetchAndRecalculateRecentJob.perform_now
  end

  def test_waits_for_unfinished_fetch_jobs
    fetch_job = create_fetch_job
    RecentTournamentResultsJob.expects(:perform_now).with(14)
    RatingCalculationJob.expects(:perform_later).with(weeks: 2)

    job = FetchAndRecalculateRecentJob.new
    job.expects(:sleep).with do |_interval|
      fetch_job.update!(finished_at: Time.current)
      true
    end

    job.perform_now
  end

  def test_finished_fetch_jobs_do_not_delay_recalculation
    create_fetch_job(finished_at: Time.current)
    RecentTournamentResultsJob.expects(:perform_now).with(14)
    RatingCalculationJob.expects(:perform_later).with(weeks: 2)

    job = FetchAndRecalculateRecentJob.new
    job.expects(:sleep).never

    job.perform_now
  end

  def test_failed_fetch_jobs_do_not_block_recalculation
    failed_job = create_fetch_job
    SolidQueue::FailedExecution.create!(job: failed_job, error: "boom")
    RecentTournamentResultsJob.expects(:perform_now).with(14)
    RatingCalculationJob.expects(:perform_later).with(weeks: 2)

    job = FetchAndRecalculateRecentJob.new
    job.expects(:sleep).never

    job.perform_now
  end

  def test_other_unfinished_jobs_do_not_count_as_fetches
    SolidQueue::Job.create!(queue_name: "wrappers", class_name: "TeamsJob")
    RecentTournamentResultsJob.expects(:perform_now).with(14)
    RatingCalculationJob.expects(:perform_later).with(weeks: 2)

    job = FetchAndRecalculateRecentJob.new
    job.expects(:sleep).never

    job.perform_now
  end

  def test_gives_up_when_fetches_never_finish
    create_fetch_job
    RecentTournamentResultsJob.expects(:perform_now).with(14)
    RatingCalculationJob.expects(:perform_later).never

    job = FetchAndRecalculateRecentJob.new
    job.stubs(:sleep).with do |_interval|
      travel FetchAndRecalculateRecentJob::MAX_WAIT
      true
    end

    error = assert_raises(RuntimeError) { job.perform_now }
    assert_match(/still pending/, error.message)
  end

  private

  def create_fetch_job(finished_at: nil)
    SolidQueue::Job.create!(queue_name: "chgk_info_import",
      class_name: "SingleTournamentResultsJob", finished_at:)
  end
end
