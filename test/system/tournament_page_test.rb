require "test_helper"

class TournamentPageTest < ActionDispatch::IntegrationTest
  include ActiveRecord::TestFixtures
  include Capybara::DSL

  fixtures :teams, :players, :towns, :tournaments, :tournament_results, :tournament_rosters

  def setup
    @tournament_id = 1
    @tournament_title = "Bled Cup"
  end

  def tournament_url(tournament_id)
    "/b/tournament/#{tournament_id}"
  end

  test "tournament_url page has its title, date, and link to rating.chgk.info" do
    visit tournament_url(@tournament_id)
    assert_text @tournament_title
    assert_text "2 октября 2024 года — 3 октября 2024 года"
    assert_equal "Страница на rating.chgk.info",
      find_link(href: "https://rating.chgk.info/tournament/#{@tournament_id}").text
  end

  test "tournament table has correct headers" do
    visit tournament_url(@tournament_id)
    within "table" do
      headers = %w[Команда Место Город Взятые Рейтинг Прогноз D1 D2 RG R RT RB TrueDL]
      headers.each do |header|
        assert_selector "th", text: header
      end
    end
  end

  test "tournament page has a list of teams with their results" do
    visit tournament_url(@tournament_id)
    within first("tbody") do
      rows = all("tr")
      assert_equal 3, rows.count
    end
  end

  test "tournament table has correct first place" do
    visit tournament_url(@tournament_id)
    within first("tbody") do
      rows = all("tr")
      within rows.first do
        assert_text "Trivia Newton John"
        assert_text "1"
        assert_text "Giethoorn"
        assert_text "30"
      end
    end
  end

  test "tournament table has correct second place" do
    visit tournament_url(@tournament_id)
    within first("tbody") do
      rows = all("tr")
      within rows[1] do
        assert_text "Knowledgeable Nightowls"
        assert_text "2"
        assert_text "Bled"
        assert_text "22"
      end
    end
  end

  test "tournament table has correct third place" do
    visit tournament_url(@tournament_id)
    within first("tbody") do
      rows = all("tr")
      within rows[2] do
        assert_text "One-off"
        assert_text "3"
        assert_text "Hallstatt"
        assert_text "21"
      end
    end
  end
end
