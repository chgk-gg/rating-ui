require "test_helper"
require "vcr"

class BaseRostersJobTest < ActiveSupport::TestCase
  CURRENT_SEASON_ID = 60
  TEAM_IDS = [62868, 85064].freeze

  setup do
    BaseRoster.where(team_id: TEAM_IDS).delete_all
    TournamentResult.delete_all
    Tournament.delete_all

    tournament = Tournament.create!(id: 1, title: "Rating Tournament", maii_rating: true,
      start_datetime: Time.current)
    TEAM_IDS.each do |team_id|
      TournamentResult.create!(tournament:, team_id:, total: 0, position: 1)
    end

    # The job sleeps a random amount between teams to be gentle on the API.
    BaseRostersJob.any_instance.stubs(:sleep)
  end

  test "job populates base rosters for teams from rating tournaments" do
    VCR.use_cassette("base_rosters_data") do
      BaseRostersJob.perform_now("from_rating_tournaments")
    end

    TEAM_IDS.each do |team_id|
      assert BaseRoster.exists?(team_id:, season_id: CURRENT_SEASON_ID),
        "expected a current-season roster for team #{team_id}"
    end
  end

  test "job removes stale roster entries no longer returned by the API" do
    # A pair the API still returns for this team (player 24850, season 52) must survive,
    # while a fabricated pair the API no longer returns must be deleted.
    [[24_850, 52], [999_999, CURRENT_SEASON_ID]].each do |player_id, season_id|
      BaseRoster.new(team_id: TEAM_IDS.first, player_id:, season_id:,
        start_date: Date.new(2000, 1, 1)).save!(validate: false)
    end

    VCR.use_cassette("base_rosters_data") do
      BaseRostersJob.perform_now("from_rating_tournaments")
    end

    assert BaseRoster.exists?(team_id: TEAM_IDS.first, player_id: 24_850, season_id: 52),
      "expected the still-current roster entry to be kept"
    assert_not BaseRoster.exists?(team_id: TEAM_IDS.first, player_id: 999_999, season_id: CURRENT_SEASON_ID),
      "expected the stale roster entry to be deleted"
  end
end
