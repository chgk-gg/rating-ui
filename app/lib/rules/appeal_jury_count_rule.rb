# frozen_string_literal: true

module Rules
  class AppealJuryCountRule < AbstractRule
    def self.description
      "Турниры, в которых меньше трёх человек в апелляционном жюри"
    end

    def self.offenders
      tournaments = Tournament.left_joins(:tournament_appeal_jury)
        .where(start_datetime: (Time.zone.today..(Time.zone.today + 3.days)))
        .where(maii_rating: true)
        .group("tournaments.id, tournaments.title")
        .having("count(tournament_appeal_jury.id) < 3")
        .select("tournaments.id, tournaments.title")

      tournaments.map do |tournament|
        "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      end.join("\n")
    end
  end
end
