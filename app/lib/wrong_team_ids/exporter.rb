# frozen_string_literal: true

module WrongTeamIds
  class Exporter
    def self.run(with_start_date_after:)
      new(with_start_date_after:).run
    end

    def initialize(with_start_date_after:)
      @start_date = with_start_date_after
    end

    def run
      tournaments = Tournament.rating_tournaments.where(start_datetime: @start_date..)
      Rails.logger.info "checking #{tournaments.count} tournaments"

      tournaments.each_with_index do |tournament, i|
        Rails.logger.info "processing tournament #{i + 1}/#{tournaments.count}" if (i + 1) % 10 == 0

        delete_old_entries(tournament.id)
        ids_to_update = TournamentChecker.wrong_team_ids(tournament)
        next if ids_to_update.empty?

        Rails.logger.info "found #{ids_to_update.size} wrong teams ids in #{tournament.title}"
        save_to_database(ids_to_update)
      end
    end

    def delete_old_entries(tournament_id)
      WrongTeamId.where(tournament_id:).delete_all
    end

    def save_to_database(ids_changes)
      ids_changes.each do |change|
        WrongTeamId.create(tournament_id: change.tournament_id, old_team_id: change.old_id, new_team_id: change.new_id)
      end
    end
  end
end
