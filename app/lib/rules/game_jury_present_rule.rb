# frozen_string_literal: true

module Rules
  class GameJuryPresentRule < AbstractRule
    def self.description
      "Турниры, в которых не указано ИЖ"
    end

    def self.offenders
      tournaments = Tournament.left_joins(:tournament_game_jury)
        .where(start_datetime: (Time.zone.today..(Time.zone.today + 3.days)))
        .where(maii_rating: true)
        .group("tournaments.id, tournaments.title")
        .having("count(tournament_game_jury.id) = 0")
        .select("tournaments.id, tournaments.title")

      tournaments.map do |tournament|
        "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      end.join("\n")
    end
  end
end
