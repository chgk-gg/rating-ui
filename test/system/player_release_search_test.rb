require "test_helper"

class PlayerReleaseSearchTest < ActionDispatch::IntegrationTest
  fixtures :seasons, :teams, :players, :towns, :base_rosters

  def assert_hiroshi_tanaka_found
    assert_selector "table tbody tr", count: 1

    within "table" do
      assert_selector "tr", text: "Hiroshi"
      assert_selector "tr", text: "Tanaka"
    end
  end

  test "player release can be searched by first name" do
    visit "/b/players"
    fill_in "first_name", with: "Hiroshi"
    click_on("Поиск")
    assert_hiroshi_tanaka_found
  end

  test "player release can be searched by last name" do
    visit "/b/players"
    fill_in "last_name", with: "Tanaka"
    click_on("Поиск")
    assert_hiroshi_tanaka_found
  end

  test "player release can be searched by first and last name combination" do
    visit "/b/players"
    fill_in "first_name", with: "Hiroshi"
    fill_in "last_name", with: "Tanaka"
    click_on("Поиск")
    assert_hiroshi_tanaka_found
  end
end
