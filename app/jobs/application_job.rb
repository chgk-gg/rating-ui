class ApplicationJob < ActiveJob::Base
  HIGH_PRIORITY = 0
  MEDIUM_PRIORITY = 1
  LOW_PRIORITY = 2

  STATEMENT_TIMEOUT = ENV.fetch("JOB_STATEMENT_TIMEOUT", 30_000).to_i

  queue_with_priority MEDIUM_PRIORITY

  # Ensure jobs always use the primary database for writes
  around_perform do |_job, block|
    ActiveRecord::Base.connected_to(role: :writing, &block)
  end

  # Allow jobs to run longer queries than the 5s limit for web requests.
  around_perform do |_job, block|
    ActiveRecord::Base.connection.execute("SET statement_timeout TO #{STATEMENT_TIMEOUT}")
    block.call
  ensure
    web_timeout = ActiveRecord::Base.connection_db_config
      .configuration_hash.dig(:variables, :statement_timeout) || 10_000
    ActiveRecord::Base.connection.execute("SET statement_timeout TO #{web_timeout.to_i}")
  end

  # Ensure job scheduling (perform_later) uses primary database for Solid Queue
  around_enqueue do |_job, block|
    ActiveRecord::Base.connected_to(role: :writing, &block)
  end
end
