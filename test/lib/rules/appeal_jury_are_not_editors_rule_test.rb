# frozen_string_literal: true

require "test_helper"

module Rules
  class AppealJuryAreNotEditorsRuleTest < ActiveSupport::TestCase
    test "offenders returns empty string when no tournaments have overlap" do
      result = AppealJuryAreNotEditorsRule.offenders
      assert_equal "", result
    end

    test "offenders includes tournament where same player is editor and appeal jury" do
      player = Player.create!(id: 1, first_name: "John", last_name: "Doe")
      tournament = Tournament.create!(
        id: 1,
        title: "Test Tournament",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )

      TournamentEditor.create!(tournament: tournament, player: player)
      TournamentAppealJury.create!(tournament: tournament, player: player)

      result = AppealJuryAreNotEditorsRule.offenders
      expected = "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      assert_equal expected, result
    end

    test "offenders excludes tournament where different players are editors and appeal jury" do
      player1 = Player.create!(id: 1, first_name: "John", last_name: "Doe")
      player2 = Player.create!(id: 2, first_name: "Jane", last_name: "Smith")
      tournament = Tournament.create!(
        id: 2,
        title: "Tournament with different roles",
        start_datetime: Time.zone.today + 2.days,
        maii_rating: true
      )

      TournamentEditor.create!(tournament: tournament, player: player1)
      TournamentAppealJury.create!(tournament: tournament, player: player2)

      result = AppealJuryAreNotEditorsRule.offenders
      assert_equal "", result
    end

    test "offenders excludes tournament with only editors but no appeal jury" do
      player = Player.create!(id: 3, first_name: "Editor", last_name: "Only")
      tournament = Tournament.create!(
        id: 3,
        title: "Tournament with only editor",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )

      TournamentEditor.create!(tournament: tournament, player: player)

      result = AppealJuryAreNotEditorsRule.offenders
      assert_equal "", result
    end

    test "offenders excludes tournament with only appeal jury but no editors" do
      player = Player.create!(id: 4, first_name: "Jury", last_name: "Only")
      tournament = Tournament.create!(
        id: 4,
        title: "Tournament with only appeal jury",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )

      TournamentAppealJury.create!(tournament: tournament, player: player)

      result = AppealJuryAreNotEditorsRule.offenders
      assert_equal "", result
    end

    test "offenders includes tournament with multiple overlapping players" do
      player1 = Player.create!(id: 5, first_name: "John", last_name: "Doe")
      player2 = Player.create!(id: 6, first_name: "Jane", last_name: "Smith")
      player3 = Player.create!(id: 7, first_name: "Bob", last_name: "Wilson")

      tournament = Tournament.create!(
        id: 5,
        title: "Tournament with multiple overlaps",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )

      TournamentEditor.create!(tournament: tournament, player: player1)
      TournamentEditor.create!(tournament: tournament, player: player2)
      TournamentAppealJury.create!(tournament: tournament, player: player1)
      TournamentAppealJury.create!(tournament: tournament, player: player3)

      result = AppealJuryAreNotEditorsRule.offenders
      expected = "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      assert_equal expected, result
    end

    test "offenders only includes tournaments within date range" do
      player = Player.create!(id: 8, first_name: "Test", last_name: "Player")

      Tournament.create!(
        id: 6,
        title: "Old Tournament",
        start_datetime: Time.zone.today - 1.day,
        maii_rating: true
      ).tap do |tournament|
        TournamentEditor.create!(tournament: tournament, player: player)
        TournamentAppealJury.create!(tournament: tournament, player: player)
      end

      Tournament.create!(
        id: 7,
        title: "Future Tournament",
        start_datetime: Time.zone.today + 4.days,
        maii_rating: true
      ).tap do |tournament|
        TournamentEditor.create!(tournament: tournament, player: player)
        TournamentAppealJury.create!(tournament: tournament, player: player)
      end

      valid_tournament = Tournament.create!(
        id: 8,
        title: "Valid Tournament",
        start_datetime: Time.zone.today + 2.days,
        maii_rating: true
      )
      TournamentEditor.create!(tournament: valid_tournament, player: player)
      TournamentAppealJury.create!(tournament: valid_tournament, player: player)

      result = AppealJuryAreNotEditorsRule.offenders
      expected = "<a href='https://rating.chgk.info/tournament/#{valid_tournament.id}'>#{valid_tournament.title}</a>"
      assert_equal expected, result
    end

    test "offenders only includes tournaments with maii_rating true" do
      player = Player.create!(id: 9, first_name: "Test", last_name: "Player")

      Tournament.create!(
        id: 9,
        title: "Non-MAII Tournament",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: false
      ).tap do |tournament|
        TournamentEditor.create!(tournament: tournament, player: player)
        TournamentAppealJury.create!(tournament: tournament, player: player)
      end

      maii_tournament = Tournament.create!(
        id: 10,
        title: "MAII Tournament",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )
      TournamentEditor.create!(tournament: maii_tournament, player: player)
      TournamentAppealJury.create!(tournament: maii_tournament, player: player)

      result = AppealJuryAreNotEditorsRule.offenders
      expected = "<a href='https://rating.chgk.info/tournament/#{maii_tournament.id}'>#{maii_tournament.title}</a>"
      assert_equal expected, result
    end

    test "offenders returns multiple tournaments joined by newlines" do
      player1 = Player.create!(id: 10, first_name: "Player", last_name: "One")
      player2 = Player.create!(id: 11, first_name: "Player", last_name: "Two")

      tournament1 = Tournament.create!(
        id: 11,
        title: "First Tournament",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )
      TournamentEditor.create!(tournament: tournament1, player: player1)
      TournamentAppealJury.create!(tournament: tournament1, player: player1)

      tournament2 = Tournament.create!(
        id: 12,
        title: "Second Tournament",
        start_datetime: Time.zone.today + 2.days,
        maii_rating: true
      )
      TournamentEditor.create!(tournament: tournament2, player: player2)
      TournamentAppealJury.create!(tournament: tournament2, player: player2)

      result = AppealJuryAreNotEditorsRule.offenders
      lines = result.split("\n")

      assert_equal 2, lines.length
      assert_includes lines, "<a href='https://rating.chgk.info/tournament/#{tournament1.id}'>#{tournament1.title}</a>"
      assert_includes lines, "<a href='https://rating.chgk.info/tournament/#{tournament2.id}'>#{tournament2.title}</a>"
    end

    test "message combines description and offenders" do
      player = Player.create!(id: 12, first_name: "Message", last_name: "Test")
      tournament = Tournament.create!(
        id: 13,
        title: "Message Test Tournament",
        start_datetime: Time.zone.today + 1.day,
        maii_rating: true
      )
      TournamentEditor.create!(tournament: tournament, player: player)
      TournamentAppealJury.create!(tournament: tournament, player: player)

      expected_description = "Турниры, в которых редакторы и АЖ пересекаются"
      expected_offenders = "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      expected_message = "#{expected_description}:\n#{expected_offenders}"

      assert_equal expected_message, AppealJuryAreNotEditorsRule.message
    end

    private

    def setup
      Tournament.destroy_all
      TournamentEditor.destroy_all
      TournamentAppealJury.destroy_all
      Player.destroy_all
    end
  end
end
