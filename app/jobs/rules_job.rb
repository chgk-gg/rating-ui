class RulesJob < ApplicationJob
  def perform
    TelegramClient.send_message(Rails.application.config.test_telegram_channel, Rules::AppealJuryRule.message)
  end
end
