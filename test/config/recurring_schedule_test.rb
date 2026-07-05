require "test_helper"

class RecurringScheduleTest < ActiveSupport::TestCase
  def test_production_recurring_tasks_are_valid
    schedule = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/recurring.yml")).deep_symbolize_keys

    schedule.fetch(:production).each do |key, options|
      task = SolidQueue::RecurringTask.from_configuration(key, **options)
      assert task.valid?, "#{key} is invalid: #{task.errors.full_messages.join(", ")}"
    end
  end

  def test_recurring_task_hash_args_arrive_as_keyword_arguments
    task = SolidQueue::RecurringTask.from_configuration(
      "rating_calculation_three_weeks",
      class: "RatingCalculationJob",
      args: [{weeks: 3}],
      schedule: "10 21 * * *"
    )

    active_job = task.enqueue(at: Time.current)

    RatingCalculationJob.any_instance.expects(:perform).with(weeks: 3)
    ActiveJob::Base.execute(active_job.serialize)
  end
end
