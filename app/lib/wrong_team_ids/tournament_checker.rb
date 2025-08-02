# frozen_string_literal: true

# Given a tournament, finds teams that should be assigned a different ID.
# If a team’s roster has enough players to be continuous to some base roster,
# we should reassign it to that base roster’s team_id.
# This class returns a list of `TeamIDUpdate` structs which contain a `tournament_id`,
# an old (and wrong) `team_id` (`old_id`), and a correct `team_id` (`new_id`).
module WrongTeamIds
  class TournamentChecker
    TeamIDUpdate = Struct.new("TeamIDUpdate", :tournament_id, :old_id, :new_id)

    # @param tournament [Tournament]
    # @return [Array[TeamIDUpdate]]
    def self.wrong_team_ids(tournament)
      new(tournament).wrong_team_ids
    end

    def initialize(tournament)
      @tournament = tournament
      @release_date = next_thursday(tournament.end_datetime)
      @rosters = Hash.new { |h, k| h[k] = [] }
      @seasons = Season.where("start < ? AND \"end\" > ?", @release_date, @release_date)
    end

    def next_thursday(date)
      date = date.to_date
      date = date.next_day until date.thursday?
      date
    end

    def wrong_team_ids
      players = TournamentRoster.where(tournament: @tournament.id)

      players.each_with_object(@rosters) do |player, hash|
        hash[player.team_id] << player.player_id
      end

      @id_changes = @rosters.map do |team_id, team_players|
        deduce_team_id(team_id, team_players)
      end.compact

      mark_same_id_assignments!
      mark_potential_duplicates!
      @id_changes
    end

    def deduce_team_id(team_id, players)
      base_team_ids = fetch_base_team_ids(players:, date: @release_date)
      return if base_team_ids.empty?

      counts = base_team_ids.tally.sort_by { |_team, count| -count }
      probable_base_team, base_team_player_count = counts.first

      # skip if a top team is already correctly assigned
      return if probable_base_team == team_id
      # skip if no base team has 3 representatives
      return if base_team_player_count < 3
      # or if two teams have 4 or more (that is, the second-largest value is 4 or more)
      return if counts[1] && counts[1][1] >= 4

      return unless RosterContinuity.counts_are_high_enough?(base_players_count: base_team_player_count,
        legionnaires_count: players.size - base_team_player_count,
        date: @release_date)

      TeamIDUpdate.new(tournament_id: @tournament.id, old_id: team_id, new_id: probable_base_team)
    end

    def fetch_base_team_ids(players:, date:)
      BaseRoster.where(season_id: @seasons.pluck(:id))
        .where("start_date < ? AND (end_date IS NULL OR end_date > ?)", date, date)
        .where(player_id: players)
        .pluck(:team_id)
    end

    def mark_same_id_assignments!
      # If two ids should be changed to the same one, we don’t change them:
      # it means that a team consciously split into two (see А.3.3.2)
      ids_tally = @id_changes.map(&:new_id).tally
      duplicate_ids = ids_tally.filter_map { |id, count| id if count >= 2 }
      @id_changes.each do |id_change|
        id_change.new_id = -1 if duplicate_ids.include?(id_change.new_id)
      end
    end

    def mark_potential_duplicates!
      # If a team is assigned to an id that already existed in the tournament,
      # we check if the already existing has continuity.
      # If it does, we should assign a second team to the same ID.
      # If it does not, we should get a new ID for the old team, and preserve reassignment.
      @id_changes.each do |id_change|
        team_id = id_change.new_id
        next unless @rosters.keys.include?(team_id)

        if is_continuous_to?(@rosters[team_id], team_id)
          id_change.new_id = -1
        else
          @id_changes << TeamIDUpdate.new(tournament_id: @tournament.id, old_id: team_id, new_id: 0)
        end
      end
    end

    def is_continuous_to?(players, team_id)
      base_teams = fetch_base_team_ids(players:, date: @release_date)
      base_players_count = base_teams.count(team_id)
      RosterContinuity.counts_are_high_enough?(base_players_count:,
        legionnaires_count: players.size - base_players_count,
        date: @release_date)
    end
  end
end
