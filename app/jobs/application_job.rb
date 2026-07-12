class ApplicationJob < ActiveJob::Base
  HIGH_PRIORITY = 0
  MEDIUM_PRIORITY = 1
  LOW_PRIORITY = 2

  queue_with_priority MEDIUM_PRIORITY

  # Ensure jobs always use the primary database for writes
  around_perform do |_job, block|
    ActiveRecord::Base.connected_to(role: :writing, &block)
  end

  # Ensure job scheduling (perform_later) uses primary database for Solid Queue
  around_enqueue do |_job, block|
    ActiveRecord::Base.connected_to(role: :writing, &block)
  end
end
