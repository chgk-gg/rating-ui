# frozen_string_literal: true

Rails.application.configure do
  config.telegram_token = ENV["TELEGRAM_TOKEN"]
  config.telegram_channel = "@rating_chgkgg_technical"
  config.test_telegram_channel = "@rating_chgkgg_technical"
end
