# frozen_string_literal: true

require "test_helper"

module WrongTeamIds
  class TournamentCheckerTest < ActiveSupport::TestCase
    fixtures :tournaments, :towns, :seasons, :teams

    def setup
      # We use fixtures for stable entities in this test, but since we constantly create and destroy
      # BaseRoster and TournamentRoster, we prefer to have a clean slate for each test.
      destroy_all

      @tournament = tournaments(:tournament_1)
      @checker = TournamentChecker.new(@tournament)
      @season = seasons(:season_2024)
      @team_2 = teams(:team_2)
      @team_3 = teams(:team_3)
    end

    def teardown
      destroy_all
    end

    def destroy_all
      BaseRoster.destroy_all
      TournamentRoster.destroy_all
      WrongTeamId.destroy_all
    end

    test "next Thursday is calculated correctly" do
      assert_equal Date.new(2023, 12, 21), @checker.next_thursday(Date.new(2023, 12, 15))
      assert_equal Date.new(2023, 12, 21), @checker.next_thursday(Date.new(2023, 12, 16))
      assert_equal Date.new(2023, 12, 21), @checker.next_thursday(Date.new(2023, 12, 21))
      assert_equal Date.new(2023, 12, 28), @checker.next_thursday(Date.new(2023, 12, 22))
    end

    test "wrong_team_ids identifies team with enough base players for reassignment" do
      create_base_roster_with_4_players_for_team_2
      create_tournament_roster_with_4_base_players_wrong_team_id

      result = TournamentChecker.wrong_team_ids(@tournament)

      assert_equal 1, result.size
      update = result.first
      assert_equal @tournament.id, update.tournament_id
      assert_equal 999, update.old_id
      assert_equal 2, update.new_id
    end

    test "wrong_team_ids handles team with 3 base players and 1 legionnaire for 2022+ rules" do
      create_base_roster_with_3_players_for_team_2
      create_tournament_roster_with_3_base_players_1_legionnaire

      result = TournamentChecker.wrong_team_ids(@tournament)

      assert_equal 1, result.size
      update = result.first
      assert_equal @tournament.id, update.tournament_id
      assert_equal 888, update.old_id
      assert_equal 2, update.new_id
    end

    test "no wrong_team_ids for team with too many legionnaires for 2022+ rules" do
      create_base_roster_with_3_players_for_team_2
      create_tournament_roster_with_3_base_players_4_legionnaires

      assert_empty TournamentChecker.wrong_team_ids(@tournament)
    end

    test "no wrong_team_ids for team with insufficient base players" do
      create_base_roster_with_2_players_for_team_2
      create_tournament_roster_with_2_base_players_2_legionnaires

      assert_empty TournamentChecker.wrong_team_ids(@tournament)
    end

    test "wrong_team_ids handles multiple teams with same target base team by marking them as -1" do
      create_base_roster_with_8_players_for_team_2
      create_multiple_tournament_rosters_targeting_same_base_team

      result = TournamentChecker.wrong_team_ids(@tournament)

      assert_equal 2, result.size
      result.each do |update|
        assert_equal @tournament.id, update.tournament_id
        assert_equal(-1, update.new_id)
      end
    end

    test "wrong_team_ids handles conflicting assignment when target team already exists in tournament" do
      create_base_roster_with_8_players_for_team_2
      create_conflicting_tournament_rosters

      result = TournamentChecker.wrong_team_ids(@tournament)

      # Team 999 should be reassigned to team 2, but team 2 already exists
      # Since team 2 has continuity, team 999 gets -1 (cannot reassign)
      assert_equal 1, result.size
      update = result.first
      assert_equal 999, update.old_id
      assert_equal(-1, update.new_id)
    end

    test "no wrong_team_ids for assignment when two base teams have 4+ players each" do
      create_base_roster_with_4_players_for_multiple_teams
      create_tournament_roster_with_players_from_multiple_base_teams

      assert_empty TournamentChecker.wrong_team_ids(@tournament)
    end

    private

    def create_tournament_rosters_for_team_2_from_base_roster
      (1..4).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: @team_2.id, player_id: i, flag: 0)
      end
    end

    def create_base_roster(player_ids, team_id)
      start_date = Date.new(2024, 10, 1)
      player_ids.each do |player_id|
        BaseRoster.create(season_id: @season.id, team_id:, player_id:, start_date:, end_date: nil)
      end
    end

    def create_base_roster_with_4_players_for_team_2
      create_base_roster((1..4).to_a, @team_2.id)
    end

    def create_base_roster_with_8_players_for_team_2
      create_base_roster((1..8).to_a, @team_2.id)
    end

    def create_base_roster_with_3_players_for_team_2
      create_base_roster([1, 2, 3], @team_2.id)
    end

    def create_base_roster_with_2_players_for_team_2
      create_base_roster([1, 2], @team_2.id)
    end

    def create_base_roster_with_4_players_for_team_3
      create_base_roster((5..8).to_a, @team_3.id)
    end

    def create_base_roster_with_4_players_for_multiple_teams
      create_base_roster((1..4).to_a, @team_2.id)
      create_base_roster((5..8).to_a, @team_3.id)
    end

    def create_tournament_roster_with_4_base_players_wrong_team_id
      # Tournament team 999 has 4 players that belong to base team 2
      (1..4).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: 999, player_id: i, flag: 0)
      end
    end

    def create_tournament_roster_with_3_base_players_1_legionnaire
      # Tournament team 888 has 3 players from base team 2 + 1 legionnaire
      (1..3).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: 888, player_id: i, flag: 0)
      end
      TournamentRoster.create(tournament: @tournament, team_id: 888, player_id: 10, flag: 0)
    end

    def create_tournament_roster_with_3_base_players_4_legionnaires
      # Tournament team 777 has 3 players from base team 2 + 4 legionnaires (too many)
      (1..3).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: 777, player_id: i, flag: 0)
      end
      (11..14).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: 777, player_id: i, flag: 0)
      end
    end

    def create_tournament_roster_with_2_base_players_2_legionnaires
      # Tournament team 666 has only 2 players from base team 2 (insufficient)
      (1..2).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: 666, player_id: i, flag: 0)
      end
      (15..16).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: 666, player_id: i, flag: 0)
      end
    end

    def create_multiple_tournament_rosters_targeting_same_base_team
      # Both tournament teams 555 and 444 have 4 players from base team 2
      (1..4).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: 555, player_id: i, flag: 0)
      end
      (5..8).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: 444, player_id: i, flag: 0)
      end
    end

    def create_conflicting_tournament_rosters
      # Team 2 exists in tournament with players that DO have continuity with base team 2
      # (3 base players + 1 legionnaire meets 2022+ rules)
      (1..3).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: @team_2.id, player_id: i, flag: 0)
      end
      TournamentRoster.create(tournament: @tournament, team_id: @team_2.id, player_id: 20, flag: 0)

      # Team 999 has all 4 base players from base team 2
      (5..8).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: 999, player_id: i, flag: 0)
      end
    end

    def create_tournament_roster_with_players_from_multiple_base_teams
      # Tournament team has 4 players from team 2 and 4 players from team 3
      (1..4).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: 333, player_id: i, flag: 0)
      end
      (5..8).each do |i|
        TournamentRoster.create(tournament: @tournament, team_id: 333, player_id: i, flag: 0)
      end
    end
  end
end
