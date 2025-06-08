class ApplicationJob < ActiveJob::Base
  # Ensure jobs always use the primary database for writes
  around_perform do |_job, block|
    ActiveRecord::Base.connected_to(role: :writing, &block)
  end

  # Ensure job scheduling (perform_later) uses primary database for Solid Queue
  around_enqueue do |_job, block|
    ActiveRecord::Base.connected_to(role: :writing, &block)
  end
end
