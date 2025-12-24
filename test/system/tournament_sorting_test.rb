require "test_helper"

class TournamentSortingTest < ActionDispatch::IntegrationTest
  include ActiveRecord::TestFixtures
  include Capybara::DSL

  fixtures :teams, :players, :towns, :tournaments, :tournament_results, :tournament_rosters

  def setup
    Capybara.current_driver = :selenium_chrome_headless
    @tournament_id = 1
  end

  def teardown
    Capybara.use_default_driver
  end

  def tournament_url(tournament_id)
    "/b/tournament/#{tournament_id}"
  end

  test "tournament results table has sortable headers" do
    visit tournament_url(@tournament_id)

    within "table" do
      assert_selector "th[data-action='click->table-sort#sort']", minimum: 1
      assert_selector "th[data-sort-column='0']", text: "Место"
      assert_selector "th[data-sort-column='3']", text: "Взятые"
      assert_selector "th[data-sort-column='4']", text: "Рейтинг"
    end
  end

  test "clicking place header sorts table by place descending" do
    visit tournament_url(@tournament_id)

    find("th[data-sort-column='0']").click

    within "table tbody" do
      rows = all("tr")
      places = rows.map { |row| row.all("td")[0].text.to_i }
      assert_equal [3, 2, 1], places, "Table should be sorted by place descending"
    end
  end

  test "clicking place header twice sorts table by place ascending" do
    visit tournament_url(@tournament_id)

    find("th[data-sort-column='0']").click
    find("th[data-sort-column='0']").click

    within "table tbody" do
      rows = all("tr")
      places = rows.map { |row| row.all("td")[0].text.to_i }
      assert_equal [1, 2, 3], places, "Table should be sorted by place ascending"
    end
  end

  test "clicking points header sorts table by points descending" do
    visit tournament_url(@tournament_id)

    find("th[data-sort-column='3']").click

    within "table tbody" do
      rows = all("tr")
      points = rows.map { |row| row.all("td")[3].text.to_i }
      assert_equal points, points.sort.reverse, "Table should be sorted by points descending"
    end
  end

  test "sort indicator appears on sorted column" do
    visit tournament_url(@tournament_id)

    header = find("th[data-sort-column='0']")
    header.click

    indicator = header.find("[data-sort-indicator]")
    assert_equal "↓", indicator.text, "Descending indicator should be shown"

    header.click
    assert_equal "↑", indicator.text, "Ascending indicator should be shown"
  end
end
