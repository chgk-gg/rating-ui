require "test_helper"

class RatingCalculationJobTest < ActiveSupport::TestCase
  include WebMock::API

  APP_NAME = "rating-calculation-test"
  MACHINES_URL = "https://api.machines.dev/v1/apps/#{APP_NAME}/machines".freeze

  def setup
    Rails.application.config.fly_api_token = "test-token"
    Rails.application.config.rating_calculation_app_name = APP_NAME

    stub_request(:post, "https://api.fly.io/graphql")
      .to_return(json_response({data: {app: {currentReleaseUnprocessed: {imageRef: "registry.fly.io/calc:tag"}}}}))
    stub_request(:post, MACHINES_URL)
      .to_return(json_response({id: "machine-1", instance_id: "instance-1"}))
    stub_wait_request.to_return(json_response({ok: true}))
  end

  def teardown
    WebMock.reset!
  end

  def test_runs_machine_and_enqueues_destruction_on_success
    stub_machine_with_exit_code(0)
    MachineDestructionJob.expects(:perform_later).with(APP_NAME, "machine-1")
    RatingCalculationJob.perform_now
  end

  def test_raises_and_still_enqueues_destruction_on_nonzero_exit_code
    stub_machine_with_exit_code(3)
    MachineDestructionJob.expects(:perform_later).with(APP_NAME, "machine-1")
    error = assert_raises(RuntimeError) { RatingCalculationJob.perform_now }
    assert_match(/exit code 3/, error.message)
  end

  def test_enqueues_views_and_truedl_refresh_on_success
    stub_machine_with_exit_code(0)
    MaterializedViewsJob.expects(:perform_later).with(InModel::DEFAULT_MODEL)
    TrueDLForRecentTournamentsJob.expects(:perform_later).with(InModel::DEFAULT_MODEL, 30)
    Rails.cache.expects(:clear)
    RatingCalculationJob.perform_now
  end

  def test_does_not_refresh_views_on_failure
    stub_machine_with_exit_code(3)
    MaterializedViewsJob.expects(:perform_later).never
    TrueDLForRecentTournamentsJob.expects(:perform_later).never
    Rails.cache.expects(:clear).never
    assert_raises(RuntimeError) { RatingCalculationJob.perform_now }
  end

  def test_passes_release_dates_as_env_vars
    stub_machine_with_exit_code(0)
    RatingCalculationJob.perform_now(first_release_date: "2025-09-04", last_release_date: Date.new(2026, 7, 2))
    assert_requested(:post, MACHINES_URL) do |request|
      config = JSON.parse(request.body)["config"]
      config["env"] == {"FIRST_RELEASE_DATE" => "2025-09-04", "LAST_RELEASE_DATE" => "2026-07-02"} &&
        config["image"] == "registry.fly.io/calc:tag" &&
        config["restart"] == {"policy" => "no"}
    end
  end

  def test_omits_env_vars_when_dates_are_not_given
    stub_machine_with_exit_code(0)
    RatingCalculationJob.perform_now
    assert_requested(:post, MACHINES_URL) do |request|
      JSON.parse(request.body)["config"]["env"] == {}
    end
  end

  def test_rejects_malformed_dates_before_starting_a_machine
    error = assert_raises(ArgumentError) { RatingCalculationJob.perform_now(first_release_date: "September 2025") }
    assert_match(/first_release_date/, error.message)
    assert_not_requested(:post, MACHINES_URL)
  end

  def test_weeks_starts_from_the_thursday_of_that_iso_week
    stub_machine_with_exit_code(0)
    travel_to Date.new(2026, 7, 4) do # a Saturday
      RatingCalculationJob.perform_now(weeks: 3)
    end
    assert_requested(:post, MACHINES_URL) do |request|
      JSON.parse(request.body)["config"]["env"] == {"FIRST_RELEASE_DATE" => "2026-06-11"}
    end
  end

  def test_tolerates_transient_wait_errors
    stub_machine_with_exit_code(0)
    stub_wait_request.to_return({status: 500, body: "flaky"}, json_response({ok: true}))
    RatingCalculationJob.any_instance.stubs(:sleep)

    RatingCalculationJob.perform_now

    assert_requested(:get, "#{MACHINES_URL}/machine-1/wait", query: wait_query, times: 2)
  end

  def test_gives_up_after_consecutive_wait_errors
    stub_wait_request.to_return(status: 500, body: "boom")
    RatingCalculationJob.any_instance.stubs(:sleep)
    MachineDestructionJob.expects(:perform_later).with(APP_NAME, "machine-1")

    assert_raises(Fly::MachinesClient::Error) { RatingCalculationJob.perform_now }

    assert_requested(:get, "#{MACHINES_URL}/machine-1/wait",
      query: wait_query, times: RatingCalculationJob::MAX_CONSECUTIVE_WAIT_ERRORS)
  end

  def test_rejects_weeks_combined_with_first_release_date
    error = assert_raises(ArgumentError) do
      RatingCalculationJob.perform_now(weeks: 3, first_release_date: "2026-01-01")
    end
    assert_match(/not both/, error.message)
    assert_not_requested(:post, MACHINES_URL)
  end

  private

  # webmock's assertions don't increment minitest's counter unless
  # webmock/minitest is required, which would patch teardown suite-wide
  def assert_requested(*args, &block)
    self.assertions += 1
    super
  end

  def wait_query
    {state: "stopped", instance_id: "instance-1", timeout: RatingCalculationJob::WAIT_TIMEOUT.to_s}
  end

  def stub_wait_request
    stub_request(:get, "#{MACHINES_URL}/machine-1/wait").with(query: wait_query)
  end

  def stub_machine_with_exit_code(code)
    stub_request(:get, "#{MACHINES_URL}/machine-1")
      .to_return(json_response({
        id: "machine-1",
        state: "stopped",
        events: [{type: "exit", request: {exit_event: {exit_code: code}}}]
      }))
  end

  def json_response(body)
    {status: 200, body: body.to_json, headers: {"Content-Type" => "application/json"}}
  end
end
