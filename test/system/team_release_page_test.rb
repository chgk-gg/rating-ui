require "test_helper"

class TeamReleasePageTest < ActionDispatch::IntegrationTest
  fixtures :teams, :towns

  def assert_row_has_correct_team(row, expected_place, expected_team, expected_city, expected_rating)
    place, team, city, rating = row
    assert_equal place, expected_place
    assert_equal team, expected_team
    assert_equal city, expected_city
    assert_equal rating, expected_rating
  end

  def latest_release_teams
    {
      1 => ["1", "Trivia Newton John", "Giethoorn", "14300\n+300"],
      2 => ["2", "The Fact Furious", "Gruyères", "12000\n−100"],
      3 => ["3", "The Lexicon Artists", "Giethoorn", "8000"],
      4 => ["4 ↓1", "The Thinking Caps", "Bibury", "7500"]
    }
  end

  test "latest release is shown by default" do
    visit "/"

    assert_selector "#releases_" do
      options = all("option").map(&:text)
      assert_equal ["19 сентября 2024 года", "12 сентября 2024 года", "5 сентября 2024 года"], options
    end

    assert_equal "12 сентября 2024 года", find("select#releases_ option[selected]").text
  end

  test "table for the latest release has correct data" do
    visit "/"

    assert_selector "table tbody tr", count: 4

    latest_release_teams.each do |place, team|
      assert_row_has_correct_team(all("table tr:nth-child(#{place}) td").map(&:text), *team)
    end
  end

  test "release can be opened by its id" do
    visit "/b/2"

    assert_selector "table tbody tr", count: 4

    latest_release_teams.each do |place, team|
      assert_row_has_correct_team(all("table tr:nth-child(#{place}) td").map(&:text), *team)
    end
  end

  test "does not make database queries for models" do
    count, matching_queries = count_queries("FROM \"models\"") do
      visit "/"
    end

    assert_equal 0, count, "Found #{count} model queries: #{matching_queries.join("\n")}"
  end
end
