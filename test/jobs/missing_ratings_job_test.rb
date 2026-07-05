require "test_helper"

class MissingRatingsJobTest < ActiveSupport::TestCase
  def setup
    Tournament.destroy_all
    TournamentResult.destroy_all
    ActiveRecord::Base.connection.execute("DELETE FROM b.tournament_result")
    @job = MissingRatingsJob.new
  end

  def create_tournament(id:, end_datetime: Time.zone.today - 10.days, maii_rating: true, with_results: true)
    tournament = Tournament.create!(
      id: id,
      title: "Tournament #{id}",
      end_datetime: end_datetime,
      maii_rating: maii_rating
    )
    TournamentResult.create!(tournament: tournament, team_id: 1, points: 10) if with_results
    tournament
  end

  def link(tournament)
    "<a href='https://rating.chgk.info/tournament/#{tournament.id}'>#{tournament.title}</a>"
  end

  test "does not send a message when there are no tournaments" do
    TelegramClient.expects(:send_message).never
    @job.perform
  end

  test "sends a message for a tournament with results but no ratings" do
    tournament = create_tournament(id: 1)

    expected = "Турниры с результатами, но без рейтинга:\n#{link(tournament)}"
    TelegramClient.expects(:send_message).with(Rails.application.config.test_telegram_channel, expected)
    @job.perform
  end

  test "does not report a tournament that has ratings" do
    tournament = create_tournament(id: 2)
    create_tournament_rating(tournament_id: tournament.id, team_id: 1)

    TelegramClient.expects(:send_message).never
    @job.perform
  end

  test "does not report a tournament without results" do
    create_tournament(id: 3, with_results: false)

    TelegramClient.expects(:send_message).never
    @job.perform
  end

  test "does not report a tournament whose results all have NULL points" do
    tournament = create_tournament(id: 7, with_results: false)
    TournamentResult.create!(tournament: tournament, team_id: 1, points: nil)
    TournamentResult.create!(tournament: tournament, team_id: 2, points: nil)

    TelegramClient.expects(:send_message).never
    @job.perform
  end

  test "reports a tournament where at least one result has points" do
    tournament = create_tournament(id: 8, with_results: false)
    TournamentResult.create!(tournament: tournament, team_id: 1, points: nil)
    TournamentResult.create!(tournament: tournament, team_id: 2, points: 5)

    expected = "Турниры с результатами, но без рейтинга:\n#{link(tournament)}"
    TelegramClient.expects(:send_message).with(Rails.application.config.test_telegram_channel, expected)
    @job.perform
  end

  test "does not report tournaments outside the recency window" do
    create_tournament(id: 4, end_datetime: Time.zone.today - 1.day)
    create_tournament(id: 5, end_datetime: Time.zone.today - 22.days)

    TelegramClient.expects(:send_message).never
    @job.perform
  end

  test "does not report non-rating tournaments" do
    create_tournament(id: 6, maii_rating: false)

    TelegramClient.expects(:send_message).never
    @job.perform
  end

  test "reports at most five tournaments, earliest first" do
    tournaments = (1..6).map do |i|
      create_tournament(id: i, end_datetime: Time.zone.today - 2.days - i.days)
    end

    expected = "Турниры с результатами, но без рейтинга:\n" +
      tournaments.drop(1).reverse.map { |tournament| link(tournament) }.join("\n")
    TelegramClient.expects(:send_message).with(Rails.application.config.test_telegram_channel, expected)
    @job.perform
  end
end
