# Basic auth for the Mission Control dashboard.
# Enabled with `config.mission_control.jobs.base_controller_class = "MissionControlController"` in `config/application.rb`.
class MissionControlController < ActionController::Base # rubocop:disable Rails/ApplicationController
  before_action :authenticate

  private

  def authenticate
    return true unless Rails.env.production?

    username, password = ENV["MISSION_CONTROL_USERNAME"], ENV["MISSION_CONTROL_PASSWORD"]
    raise "Missing username or password" unless username.present? && password.present?

    authenticate_or_request_with_http_basic do |request_username, request_password|
      ActiveSupport::SecurityUtils.secure_compare(request_username, username) &
        ActiveSupport::SecurityUtils.secure_compare(request_password, password)
    end
  end
end
