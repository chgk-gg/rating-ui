require "test_helper"

class TeamReleaseSearchTest < ActionDispatch::IntegrationTest
  fixtures :seasons, :teams, :players, :towns, :base_rosters

  def assert_trivia_newton_john_found
    assert_selector "table tbody tr", count: 1

    within "table" do
      assert_selector "tr", text: "Trivia Newton John"
      assert_selector "tr", text: "14300"
      assert_selector "tr", text: "+300"
    end
  end

  test "release can be searched by a team’s name" do
    visit "/"
    fill_in "team", with: "Trivia Newton John"
    click_on("Поиск")
    assert_trivia_newton_john_found
  end

  test "release can be searched by any part of a team’s name" do
    visit "/"
    fill_in "team", with: "newt"
    click_on("Поиск")

    assert_trivia_newton_john_found
  end

  test "asterisk can be used in search" do
    visit "/"
    fill_in "team", with: "*newt*"
    click_on("Поиск")

    assert_trivia_newton_john_found
  end

  test "release can be searched by city" do
    visit "/"
    fill_in "city", with: "Giethoorn"
    click_on("Поиск")

    assert_selector "table tbody tr", count: 2

    city_column_values = all("table tr td:nth-child(4)").map(&:text).uniq
    assert_equal ["Giethoorn"], city_column_values
  end
end
