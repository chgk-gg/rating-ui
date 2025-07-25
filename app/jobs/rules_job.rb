class RulesJob < ApplicationJob
  def perform
    rules = [Rules::AppealJuryRule]
    messages = rules.map do |rule_class, hash|
      message = rule_class.message
      if message.blank?
        Rails.logger.info "No offenders found for #{rule_class}."
        next
      end

      rule_class.message
    end.compact

    messages.each { |message| TelegramClient.send_message(Rails.application.config.test_telegram_channel, message) }
  end
end
