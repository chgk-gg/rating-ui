class MissingRatingsJob < ApplicationJob
  queue_with_priority HIGH_PRIORITY

  MAX_TOURNAMENTS = 5

  def perform
    return if tournaments.empty?

    TelegramClient.send_message(Rails.application.config.test_telegram_channel, message)
  end

  private

  def tournaments
    @tournaments ||= Tournament
      .rating_tournaments
      .where(end_datetime: (Time.zone.today - 21.days)..(Time.zone.today - 2.days))
      .where("EXISTS (SELECT 1 FROM tournament_results r WHERE r.tournament_id = tournaments.id AND r.points IS NOT NULL)")
      .where("NOT EXISTS (SELECT 1 FROM #{InModel::DEFAULT_MODEL}.tournament_result tr WHERE tr.tournament_id = tournaments.id)")
      .order(:end_datetime)
      .limit(MAX_TOURNAMENTS)
  end

  def message
    links = tournaments.map do |tournament|
      "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
    end.join("\n")
    "Турниры с результатами, но без рейтинга:\n#{links}"
  end
end
