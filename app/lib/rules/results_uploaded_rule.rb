# frozen_string_literal: true

module Rules
  class ResultsUploadedRule < AbstractRule
    def self.description
      "Очные турниры, в которых через 7 суток после окончания не загружены результаты"
    end

    def self.offenders
      tournaments = Tournament
        .rating_tournaments
        .where(end_datetime: ((Time.zone.today - 15.days)..(Time.zone.today - 8.days)))
        .where(type: "Обычный")
        .where.missing(:tournament_results)
        .where.missing(:tournament_rosters)

      tournaments.map do |tournament|
        "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      end.join("\n")
    end
  end
end
