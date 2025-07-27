require "test_helper"

class PlayerPageTest < ActionDispatch::IntegrationTest
  include ActiveRecord::TestFixtures
  include Capybara::DSL

  fixtures :seasons, :teams, :players, :towns, :base_rosters

  def setup
    @player_id = 3
    @player_name = "Carlos Garcia"
  end

  def player_url(player_id)
    "/b/player/#{player_id}"
  end

  test "player page has their name and link to rating.chgk.info" do
    visit player_url(@player_id)

    assert_text @player_name
    assert_equal "Страница на rating.chgk.info", find_link(href: "https://rating.chgk.info/player/#{@player_id}").text
  end

  test "player page has a list of tournaments" do
    visit player_url(@player_id)

    within first("table") do
      assert_text "Турнир"
      assert_text "Место"
      assert_text "Рейтинг"
      assert_text "Турнир"
      assert_text "Команда"
      assert_text "Бонус"
      assert_text "Δ"
    end
  end
end
