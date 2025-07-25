# frozen_string_literal: true

require "httparty"

class TelegramClient
  include HTTParty

  base_uri "https://api.telegram.org"

  class << self
    def send_message(channel_name, message_text)
      return false if token.blank?

      post("/bot#{token}/sendMessage", {
        body: {
          chat_id: channel_name,
          text: message_text,
          parse_mode: "HTML"
        }
      })
    rescue => e
      Rails.logger.error "TelegramClient error: #{e.message}"
      false
    end

    private

    def token
      Rails.application.config.telegram_token
    end
  end
end
