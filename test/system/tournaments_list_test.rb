require "test_helper"

class TournamentsListTest < ActionDispatch::IntegrationTest
  include ActiveRecord::TestFixtures
  include Capybara::DSL

  fixtures :tournaments

  def tournaments_url
    "/b/tournaments"
  end

  test "tournaments list page has tournaments table" do
    visit tournaments_url
    assert_selector "table"
    within "table" do
      assert_selector "th", text: "Турнир"
      assert_selector "th", text: "Тип"
      assert_selector "th", text: "Дата"
    end
  end

  test "tournaments list displays tournament data from fixtures" do
    visit tournaments_url
    within "table tbody" do
      assert_text "Bled Cup"
      assert_text "Bled Cup Mirror"
      assert_text "Cesky Krumlov Championship 2025"

      rows = all("tr")
      assert_equal 3, rows.count
    end
  end

  test "tournaments list shows paging elements with small from and to values" do
    visit "#{tournaments_url}?from=2&to=3"
    assert_selector "table"

    within "table tbody" do
      rows = all("tr")
      assert_equal 2, rows.count
    end

    assert_link "←"
    assert_link "→"
  end

  test "tournaments can be searched by name" do
    visit tournaments_url
    fill_in "name", with: "Bled"
    click_on "Поиск"

    within "table tbody" do
      assert_text "Bled Cup"
      assert_text "Bled Cup Mirror"
      rows = all("tr")
      assert_equal 2, rows.count
    end
  end

  test "tournaments can be searched by partial name" do
    visit tournaments_url
    fill_in "name", with: "Cesky"
    click_on "Поиск"

    within "table tbody" do
      assert_text "Cesky Krumlov Championship 2025"
      rows = all("tr")
      assert_equal 1, rows.count
    end
  end

  test "tournament search is case insensitive" do
    visit tournaments_url
    fill_in "name", with: "bled"
    click_on "Поиск"

    within "table tbody" do
      assert_text "Bled Cup"
      rows = all("tr")
      assert rows.count >= 1
    end
  end

  test "tournaments can be filtered by type" do
    visit tournaments_url
    select "Синхрон", from: "type_id"
    click_on "Поиск"

    within "table tbody" do
      assert_text "Bled Cup Mirror"
      rows = all("tr")
      assert_equal 1, rows.count
    end
  end
end
