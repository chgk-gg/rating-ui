class RulesJob < ApplicationJob
  TELEGRAM_MAX_MESSAGE_LENGTH = 4094 # 4096 - 2 for newlines

  def initialize
    @accumulated_message = ""
  end

  def perform
    messages = rules.map do |rule_class|
      message = rule_class.message
      Rails.logger.info "No offenders found for #{rule_class}." if message.blank?
      message
    end.compact

    messages.each do |message|
      if (@accumulated_message + message).length > TELEGRAM_MAX_MESSAGE_LENGTH
        send_accumulated_message
        @accumulated_message = message
      elsif @accumulated_message.blank?
        @accumulated_message = message
      else
        @accumulated_message += "\n\n#{message}"
      end
    end
    send_accumulated_message
  end

  def rules
    [
      Rules::AppealJuryCountRule,
      Rules::EditorsPresentRule,
      Rules::AppealJuryAreNotEditorsRule,
      Rules::GameJuryPresentRule
    ]
  end

  def send_accumulated_message
    return if @accumulated_message.blank?

    TelegramClient.send_message(Rails.application.config.test_telegram_channel, @accumulated_message)
  end
end
