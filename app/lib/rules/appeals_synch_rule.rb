# frozen_string_literal: true

module Rules
  class AppealsSynchRule < AbstractRule
    def self.description
      "Синхронные турниры, в которых спустя 16 дней после окончания не все апелляции рассмотрены"
    end

    def self.offenders
      all_recent_tournaments = Tournament
        .rating_tournaments
        .where(end_datetime: ((Time.zone.today - 60.days)..(Time.zone.today - 16.days)))
        .where(type: "Синхрон")

      tournaments = all_recent_tournaments.select { has_active_appeals?(it.id) }

      tournaments.map do |tournament|
        "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      end.join("\n")
    end

    def self.has_active_appeals?(tournament_id)
      sleep 0.3
      Rails.logger.info("Fetching appeals for tournament ##{tournament_id}")
      api_client = ChgkInfo::APIClient.new
      appeals = api_client.tournament_appeals(tournament_id:)
      appeals.any? { it["status"] == "N" }
    end
  end
end
