# frozen_string_literal: true

module RosterContinuity
  FIRST_DATE_OF_2022_RULES = Date.new(2022, 11, 18)

  # @param [Enumerable] players List of IDs, e.g., roster in a specific tournament
  # @param [Enumerable] base_players List of IDs, base roster of a team on a specific date
  # @param [Date] date Date of a tournament: e.g., rules are different for 2021 and 2023
  # @return [Boolean]
  def self.roster_has_continuity?(players:, base_players:, date:)
    base_players_count = Set.new(base_players).intersection(Set.new(players)).size
    legionnaires_count = players.size - base_players_count
    counts_are_high_enough?(base_players_count:, legionnaires_count:, date:)
  end

  def self.counts_are_high_enough?(base_players_count:, legionnaires_count:, date:)
    if date >= FIRST_DATE_OF_2022_RULES
      (base_players_count >= 3) && (legionnaires_count < base_players_count) && (legionnaires_count <= 3)
    else
      base_players_count >= 4
    end
  end
end
