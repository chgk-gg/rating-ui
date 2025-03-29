require "test_helper"
require "vcr"

class SingleTournamentResultsJobTest < ActiveSupport::TestCase
  setup do
    @tournament_id = 10468

    Tournament.create(id: @tournament_id, title: "Test Tournament", start_datetime: Time.current)
    TournamentRoster.where(tournament_id: @tournament_id).delete_all
    TournamentResult.where(tournament_id: @tournament_id).delete_all
  end

  def check_tournament_data
    rosters = TournamentRoster.where(tournament_id: @tournament_id)
    assert_equal 172, rosters.size

    sample_player = rosters.order(:player_id).first
    assert_equal 58672, sample_player.team_id
    assert_equal 856, sample_player.player_id
    assert_equal @tournament_id, sample_player.tournament_id

    results = TournamentResult.where(tournament_id: @tournament_id)
    assert_equal 28, results.size

    sample_result = results.order(:position).first
    assert_equal 77174, sample_result.team_id
    assert_equal 1.0, sample_result.position
    assert_equal 63, sample_result.total
    assert_equal @tournament_id, sample_result.tournament_id
  end

  test "job populates database with tournament roster and result data" do
    VCR.use_cassette("tournament_#{@tournament_id}_data") do
      SingleTournamentResultsJob.perform_now(@tournament_id)

      check_tournament_data
    end
  end

  test "job replaces existing tournament data" do
    team_id = 11111
    TournamentRoster.create!(tournament_id: @tournament_id, team_id:, player_id: 22222)

    TournamentResult.create!(tournament_id: @tournament_id, team_id:, total: 5, position: 10)

    VCR.use_cassette("tournament_#{@tournament_id}_data") do
      SingleTournamentResultsJob.perform_now(@tournament_id)

      assert_not TournamentRoster.exists?(tournament_id: @tournament_id, team_id:)
      assert_not TournamentResult.exists?(tournament_id: @tournament_id, team_id:)

      check_tournament_data
    end
  end
end
