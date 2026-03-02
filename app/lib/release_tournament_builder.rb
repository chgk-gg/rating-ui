class ReleaseTournamentBuilder
  def self.build(releases, tournaments, players)
    new(releases, tournaments, players).build
  end

  def initialize(releases, tournaments, players)
    @releases = releases
    @tournaments = tournaments
    @players = players
  end

  def build
    @releases.flat_map do |release|
      tournaments_in_release = tournaments_by_release_id[release.id]
      if tournaments_in_release.nil?
        ReleaseTournamentPresenter.new(release:)
      elsif tournaments_in_release.size == 1
        tournament = tournaments_in_release.first
        ReleaseTournamentPresenter.new(release:,
          tournament:,
          players: @players[tournament.id])
      else
        rows = tournaments_in_release.map do |tournament|
          ReleaseTournamentPresenter.new(release:,
            tournament:,
            players: @players[tournament.id],
            rows: 0)
        end
        rows.first.rows = tournaments_in_release.size
        rows
      end
    end
  end

  def tournaments_by_release_id
    @tournaments.each_with_object({}) do |tournament, hash|
      (hash[tournament["release_id"]] ||= []) << tournament
    end
  end
end
