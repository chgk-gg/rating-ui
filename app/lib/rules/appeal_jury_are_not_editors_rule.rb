# frozen_string_literal: true

module Rules
  class AppealJuryAreNotEditorsRule < AbstractRule
    def self.description
      "Турниры, в которых редакторы и АЖ пересекаются"
    end

    def self.offenders
      tournaments = Tournament
        .joins(:tournament_editors)
        .joins(:tournament_appeal_jury)
        .where(start_datetime: (Time.zone.today..(Time.zone.today + 3.days)))
        .where(maii_rating: true)
        .where("tournament_editors.player_id = tournament_appeal_jury.player_id")
        .select("tournaments.id, tournaments.title")
        .group("tournaments.id, tournaments.title")

      tournaments.map do |tournament|
        "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      end.join("\n")
    end
  end
end
