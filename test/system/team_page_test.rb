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
    visit team_url(@team_id)

    season_title = if Time.zone.today.month >= 9
      "#{Time.zone.today.year}/#{(Time.zone.today.year + 1).to_s.last(2)}"
    else
      "#{Time.zone.today.year - 1}/#{Time.zone.today.year.to_s.last(2)}"
    end
    assert_text "Базовый состав на сезон #{season_title}"

    players = find("div.bg-gray-200 > div:nth-child(1)").all("p a")
    assert_equal ["Carlos Garcia", "Aisha Khan", "Hiroshi Tanaka"], players.map(&:text)
    assert_equal "/b/player/3/", players.first[:href]
  end
end
