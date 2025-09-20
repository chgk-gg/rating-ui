require "test_helper"

class TeamPageTest < ActionDispatch::IntegrationTest
  include ActiveRecord::TestFixtures
  include Capybara::DSL

  fixtures :seasons, :teams, :players, :towns, :base_rosters

  def setup
    @team_name = "Trivia Newton John"
    @team_id = 2
  end

  def team_url(team_id)
    "/b/team/#{team_id}"
  end

  test "team page has its name and link to rating.chgk.info" do
    visit team_url(@team_id)

    assert_text @team_name
    assert_equal "Страница на rating.chgk.info", find_link(href: "https://rating.chgk.info/teams/#{@team_id}").text
  end

  test "team page has its base roster" do
    Season.stubs(:current_season).returns(seasons(:season_2024))

    visit team_url(@team_id)

    assert_text "Базовый состав на сезон 2024/25"

    players = find("div.bg-gray-200 > div:nth-child(1)").all("p a")
    assert_equal ["Carlos Garcia", "Aisha Khan", "Hiroshi Tanaka"], players.map(&:text)
    assert_equal "/b/player/3/", players.first[:href]
  end
end
