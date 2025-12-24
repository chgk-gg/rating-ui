# frozen_string_literal: true

require "test_helper"

module Rules
  class ResultsUploadedRuleTest < ActiveSupport::TestCase
    def setup
      Tournament.destroy_all
      TournamentResult.destroy_all
      TournamentRoster.destroy_all
    end

    test "offenders returns empty string when no tournaments match criteria" do
      result = ResultsUploadedRule.offenders
      assert_equal "", result
    end

    test "offenders includes tournament with no results or rosters" do
      tournament = Tournament.create!(
        id: 1,
        title: "Test Tournament",
        end_datetime: Time.zone.today - 10.days,
        type: "Обычный",
        maii_rating: true
      )

      result = ResultsUploadedRule.offenders
      expected = "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      assert_equal expected, result
    end

    test "offenders excludes tournament with tournament_results" do
      tournament = Tournament.create!(
        id: 2,
        title: "Tournament with results",
        end_datetime: Time.zone.today - 10.days,
        type: "Обычный",
        maii_rating: true
      )

      TournamentResult.create!(tournament: tournament, team_id: 1)

      result = ResultsUploadedRule.offenders
      assert_equal "", result
    end

    test "offenders excludes tournament with tournament_rosters" do
      tournament = Tournament.create!(
        id: 3,
        title: "Tournament with rosters",
        end_datetime: Time.zone.today - 10.days,
        type: "Обычный",
        maii_rating: true
      )

      TournamentRoster.create!(tournament: tournament, team_id: 1, player_id: 1)

      result = ResultsUploadedRule.offenders
      assert_equal "", result
    end

    test "offenders only includes tournaments within date range" do
      Tournament.create!(
        id: 4,
        title: "Too Recent Tournament",
        end_datetime: Time.zone.today - 5.days,
        type: "Обычный",
        maii_rating: true
      )

      Tournament.create!(
        id: 5,
        title: "Too Old Tournament",
        end_datetime: Time.zone.today - 20.days,
        type: "Обычный",
        maii_rating: true
      )

      valid_tournament = Tournament.create!(
        id: 6,
        title: "Valid Tournament",
        end_datetime: Time.zone.today - 10.days,
        type: "Обычный",
        maii_rating: true
      )

      result = ResultsUploadedRule.offenders
      expected = "<a href='https://rating.chgk.info/tournament/#{valid_tournament.id}'>#{valid_tournament.title}</a>"
      assert_equal expected, result
    end

    test "offenders only includes tournaments with maii_rating true" do
      Tournament.create!(
        id: 7,
        title: "Non-MAII Tournament",
        end_datetime: Time.zone.today - 10.days,
        type: "Обычный",
        maii_rating: false
      )

      maii_tournament = Tournament.create!(
        id: 8,
        title: "MAII Tournament",
        end_datetime: Time.zone.today - 10.days,
        type: "Обычный",
        maii_rating: true
      )

      result = ResultsUploadedRule.offenders
      expected = "<a href='https://rating.chgk.info/tournament/#{maii_tournament.id}'>#{maii_tournament.title}</a>"
      assert_equal expected, result
    end

    test "offenders only includes tournaments with type Обычный" do
      Tournament.create!(
        id: 9,
        title: "Online Tournament",
        end_datetime: Time.zone.today - 10.days,
        type: "Онлайн",
        maii_rating: true
      )

      regular_tournament = Tournament.create!(
        id: 10,
        title: "Regular Tournament",
        end_datetime: Time.zone.today - 10.days,
        type: "Обычный",
        maii_rating: true
      )

      result = ResultsUploadedRule.offenders
      expected = "<a href='https://rating.chgk.info/tournament/#{regular_tournament.id}'>#{regular_tournament.title}</a>"
      assert_equal expected, result
    end

    test "offenders returns multiple tournaments joined by newlines" do
      tournament1 = Tournament.create!(
        id: 11,
        title: "First Tournament",
        end_datetime: Time.zone.today - 10.days,
        type: "Обычный",
        maii_rating: true
      )

      tournament2 = Tournament.create!(
        id: 12,
        title: "Second Tournament",
        end_datetime: Time.zone.today - 11.days,
        type: "Обычный",
        maii_rating: true
      )

      result = ResultsUploadedRule.offenders
      lines = result.split("\n")

      assert_equal 2, lines.length
      assert_includes lines, "<a href='https://rating.chgk.info/tournament/#{tournament1.id}'>#{tournament1.title}</a>"
      assert_includes lines, "<a href='https://rating.chgk.info/tournament/#{tournament2.id}'>#{tournament2.title}</a>"
    end

    test "message combines description and offenders" do
      tournament = Tournament.create!(
        id: 13,
        title: "Message Test Tournament",
        end_datetime: Time.zone.today - 10.days,
        type: "Обычный",
        maii_rating: true
      )

      expected_description = "Очные турниры, в которых через 7 суток после окончания не загружены результаты"
      expected_offenders = "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
      expected_message = "#{expected_description}:\n#{expected_offenders}"

      assert_equal expected_message, ResultsUploadedRule.message
    end
  end
end
