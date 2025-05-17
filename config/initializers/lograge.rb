# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true if Rails.env.production?
end
