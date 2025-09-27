# frozen_string_literal: true

module Rules
  class EditorsPresentRule < AbstractRule
    def self.description
      "Турниры, в которых не указаны редакторы"
    end

    def self.offenders
      tournaments = Tournament
        .rating_tournaments
        .left_joins(:tournament_editors)
        .where(start_datetime: (Time.zone.today..(Time.zone.today + 3.days)))
        .group("tournaments.id, tournaments.title")
        .having("count(tournament_editors.id) = 0")
        .select("tournaments.id, tournaments.title")

      tournaments.map do |tournament|
        "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      end.join("\n")
    end
  end
end
