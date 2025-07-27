# frozen_string_literal: true

require "test_helper"

module Rules
  class GameJuryPresentRuleTest < ActiveSupport::TestCase
    test "offenders returns empty string when no tournaments match criteria" do
      result = GameJuryPresentRule.offenders
      assert_equal "", result
    end

    test "offenders includes tournament with no game jury" do
      tournament = Tournament.create!(
        id: 1,
        title: "Test Tournament",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )

      result = GameJuryPresentRule.offenders
      expected = "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      assert_equal expected, result
    end

    test "offenders excludes tournament with game jury present" do
      tournament = Tournament.create!(
        id: 2,
        title: "Tournament with game jury",
        start_datetime: Time.zone.today + 2.days,
        maii_rating: true
      )

      player = Player.create!(id: 1, first_name: "John", last_name: "Doe")
      TournamentGameJury.create!(tournament: tournament, player: player)

      result = GameJuryPresentRule.offenders
      assert_equal "", result
    end

    test "offenders excludes tournament with multiple game jury members" do
      tournament = Tournament.create!(
        id: 3,
        title: "Tournament with multiple game jury members",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )

      player1 = Player.create!(id: 3, first_name: "John", last_name: "Doe")
      player2 = Player.create!(id: 4, first_name: "Jane", last_name: "Smith")

      TournamentGameJury.create!(tournament: tournament, player: player1)
      TournamentGameJury.create!(tournament: tournament, player: player2)

      result = GameJuryPresentRule.offenders
      assert_equal "", result
    end

    test "offenders only includes tournaments within date range" do
      Tournament.create!(
        id: 4,
        title: "Old Tournament",
        start_datetime: Time.zone.today - 1.day,
        maii_rating: true
      )

      Tournament.create!(
        id: 5,
        title: "Future Tournament",
        start_datetime: Time.zone.today + 4.days,
        maii_rating: true
      )

      valid_tournament = Tournament.create!(
        id: 6,
        title: "Valid Tournament",
        start_datetime: Time.zone.today + 2.days,
        maii_rating: true
      )

      result = GameJuryPresentRule.offenders
      expected = "<a href='https://rating.chgk.info/tournament/#{valid_tournament.id}'>#{valid_tournament.title}</a>"
      assert_equal expected, result
    end

    test "offenders only includes tournaments with maii_rating true" do
      Tournament.create!(
        id: 7,
        title: "Non-MAII Tournament",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: false
      )

      maii_tournament = Tournament.create!(
        id: 8,
        title: "MAII Tournament",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )

      result = GameJuryPresentRule.offenders
      expected = "<a href='https://rating.chgk.info/tournament/#{maii_tournament.id}'>#{maii_tournament.title}</a>"
      assert_equal expected, result
    end

    test "offenders returns multiple tournaments joined by newlines" do
      tournament1 = Tournament.create!(
        id: 9,
        title: "First Tournament",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )

      tournament2 = Tournament.create!(
        id: 10,
        title: "Second Tournament",
        start_datetime: Time.zone.today + 2.days,
        maii_rating: true
      )

      result = GameJuryPresentRule.offenders
      lines = result.split("\n")

      assert_equal 2, lines.length
      assert_includes lines, "<a href='https://rating.chgk.info/tournament/#{tournament1.id}'>#{tournament1.title}</a>"
      assert_includes lines, "<a href='https://rating.chgk.info/tournament/#{tournament2.id}'>#{tournament2.title}</a>"
    end

    test "message combines description and offenders" do
      tournament = Tournament.create!(
        id: 11,
        title: "Message Test Tournament",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )

      expected_description = "Турниры, в которых не указано ИЖ"
      expected_offenders = "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      expected_message = "#{expected_description}:\n#{expected_offenders}"

      assert_equal expected_message, GameJuryPresentRule.message
    end

    private

    def setup
      Tournament.destroy_all
      TournamentGameJury.destroy_all
      Player.destroy_all
    end
  end
end
