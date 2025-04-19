# frozen_string_literal: true

class BackupJob < ApplicationJob
  queue_as :backup

  def perform
    local_backup_file_name = Rails.root.join("tmp/backups/rating.backup")

    Rails.logger.info "starting pg_dump"
    cmd = "pg_dump -n public -n b -Fc -f #{local_backup_file_name} #{connection_string}"
    _stdout, stderr, status = Open3.capture3(cmd)

    unless status.success?
      Rails.logger.error "pg_dump failed with status #{status.exitstatus}"
      Rails.logger.error "Error details: #{stderr}"
      raise "Database backup failed: pg_dump exited with status #{status.exitstatus}. Error: #{stderr}"
    end

    Rails.logger.info "pg_dump complete, uploading to R2"
    R2.upload_file(local_backup_file_name)
    Rails.logger.info "backup completed"
  ensure
    `rm -f #{local_backup_file_name}`
  end

  def connection_string
    Rails.configuration.database_configuration[Rails.env]["url"]
  end
end
