require "test_helper"

class MachineDestructionJobTest < ActiveSupport::TestCase
  include WebMock::API
  include ActiveJob::TestHelper

  def queue_adapter_for_test
    ActiveJob::QueueAdapters::TestAdapter.new
  end

  APP_NAME = "rating-calculation-test"
  MACHINES_URL = "https://api.machines.dev/v1/apps/#{APP_NAME}/machines".freeze

  def setup
    Rails.application.config.fly_api_token = "test-token"
  end

  def teardown
    WebMock.reset!
  end

  def test_destroys_the_machine
    delete = stub_request(:delete, "#{MACHINES_URL}/machine-1")
      .with(query: {force: "true"})
      .to_return(status: 200, body: {ok: true}.to_json, headers: {"Content-Type" => "application/json"})

    MachineDestructionJob.perform_now(APP_NAME, "machine-1")

    assert_requested delete
  end

  def test_reenqueues_itself_when_destruction_fails
    stub_request(:delete, "#{MACHINES_URL}/machine-1")
      .with(query: {force: "true"})
      .to_return(status: 500, body: "boom")

    assert_enqueued_with(job: MachineDestructionJob, args: [APP_NAME, "machine-1"]) do
      MachineDestructionJob.perform_now(APP_NAME, "machine-1")
    end
  end

  private

  # webmock's assertions don't increment minitest's counter unless
  # webmock/minitest is required, which would patch teardown suite-wide
  def assert_requested(*args, &block)
    self.assertions += 1
    super
  end
end
