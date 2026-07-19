class RatingCalculationJob < ApplicationJob
  WAIT_TIMEOUT = 30 # seconds per long-poll request, kept below Net::HTTP's 60s read timeout
  MAX_CONSECUTIVE_WAIT_ERRORS = 5
  WAIT_ERROR_PAUSE = 30
  MAX_RUNTIME = 6.hours
  MACHINE_RESOURCES = {cpu_kind: "shared", cpus: 4, memory_mb: 4096}.freeze

  queue_as :rating_calculation
  queue_with_priority HIGH_PRIORITY

  # duration must cover the whole run: once the concurrency semaphore expires
  # (default 3 minutes), a second enqueued job would be unblocked and spin up a
  # parallel machine. Keep it at least as long as the job can run.
  limits_concurrency to: 1, key: :rating_calculation, duration: MAX_RUNTIME

  # Dates become the FIRST_RELEASE_DATE / LAST_RELEASE_DATE env vars read by
  # rating-b's entrypoint. When nil, the var is omitted and calc_all_releases
  # falls back to its own defaults (first new release / today).
  # Alternatively, weeks: N recalculates the last N weeks of releases.
  def perform(first_release_date: nil, last_release_date: nil, weeks: nil)
    raise ArgumentError, "pass either weeks or first_release_date, not both" if weeks && first_release_date

    first_release_date = release_date_weeks_ago(weeks) if weeks

    app_name = Rails.application.config.rating_calculation_app_name
    raise "RATING_CALCULATION_APP_NAME is not set" if app_name.blank?

    env = release_range_env(first_release_date, last_release_date)
    log "requested with #{env.empty? ? "default release range" : env.inspect}"

    image = Fly::MachinesClient.latest_image(app_name)
    log "using image #{image}"

    machine = Fly::MachinesClient.create_machine(app_name, machine_config(image, env))
    started_at = Time.current
    log "started machine #{machine["id"]} in region #{machine["region"]}"

    wait_until_stopped(app_name, machine, started_at)
    log "machine #{machine["id"]} stopped after #{elapsed(started_at)}, checking exit code"

    code = exit_code(app_name, machine["id"])
    raise "rating calculation failed with exit code #{code} after #{elapsed(started_at)}" unless code.zero?

    log "finished successfully on machine #{machine["id"]} in #{elapsed(started_at)}"
    refresh_views
  ensure
    # Hand cleanup to a separate job so a destruction failure can't mask the
    # real error raised by perform, and so it can be retried on its own.
    MachineDestructionJob.perform_later(app_name, machine["id"]) if machine
  end

  private

  # calc_all_releases steps from the first date in 7-day increments, and
  # releases come out on Thursdays, so we take the Thursday of the ISO week
  # N weeks ago.
  def release_date_weeks_ago(weeks)
    (Date.current - weeks.to_i.weeks).beginning_of_week(:monday) + 3.days
  end

  def refresh_views
    MaterializedViewsJob.perform_later(InModel::DEFAULT_MODEL)
    TrueDLForRecentTournamentsJob.perform_later(InModel::DEFAULT_MODEL, 30)
    Rails.cache.clear
  end

  def release_range_env(first_release_date, last_release_date)
    {
      "FIRST_RELEASE_DATE" => iso_date(first_release_date, :first_release_date),
      "LAST_RELEASE_DATE" => iso_date(last_release_date, :last_release_date)
    }.compact
  end

  def iso_date(value, name)
    return if value.nil?

    date = value.is_a?(Date) ? value : Date.iso8601(value.to_s)
    date.iso8601
  rescue Date::Error
    raise ArgumentError, "#{name} must be a Date or a YYYY-MM-DD string, got #{value.inspect}"
  end

  def machine_config(image, env)
    {
      image:,
      env:,
      restart: {policy: "no"},
      guest: MACHINE_RESOURCES
    }
  end

  # A single flaky Fly API response must not fail an hours-long calculation.
  # Only give up (and destroy the machine) after several consecutive failures.
  def wait_until_stopped(app_name, machine, started_at)
    deadline = started_at + MAX_RUNTIME
    consecutive_errors = 0

    loop do
      raise "machine #{machine["id"]} still running after #{MAX_RUNTIME.inspect}" if Time.current > deadline

      stopped = Fly::MachinesClient.wait_for_stop(app_name, machine["id"],
        instance_id: machine["instance_id"], timeout: WAIT_TIMEOUT)
      consecutive_errors = 0
      break if stopped

      log "machine #{machine["id"]} still running, elapsed #{elapsed(started_at)}"
    rescue Fly::MachinesClient::Error => error
      consecutive_errors += 1
      raise if consecutive_errors >= MAX_CONSECUTIVE_WAIT_ERRORS

      log "wait failed (#{consecutive_errors}/#{MAX_CONSECUTIVE_WAIT_ERRORS}), retrying: #{error.message}"
      sleep WAIT_ERROR_PAUSE
    end
  end

  def exit_code(app_name, machine_id)
    machine = Fly::MachinesClient.machine(app_name, machine_id)
    exit_event = machine["events"]&.find { |event| event["type"] == "exit" }
    code = exit_event&.dig("request", "exit_event", "exit_code")
    raise "no exit event for machine #{machine_id}, state: #{machine["state"]}" if code.nil?

    code
  end

  def elapsed(started_at)
    ActiveSupport::Duration.build((Time.current - started_at).round).inspect
  end

  def log(message)
    Rails.logger.info "rating calculation: #{message}"
  end
end
