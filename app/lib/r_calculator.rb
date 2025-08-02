# frozen_string_literal: true

Rs = Data.define(:rg, :r, :rt, :rb)

class RCalculator
  def self.calculate(model:, team_id:, players:, date:)
    new(model, team_id, players, date).ratings
  end

  attr_reader :date, :players, :team_id

  def initialize(model, team_id, players, date)
    @model = model
    @team_id = team_id
    @players = players
    @date = date
    @q = @model.release_for_date(@date).q
  end

  def ratings
    players_ratings = @model.players_ratings_on_date(players:, date:).pluck("rating")
    rt = calculate_rt(players_ratings)
    base_players = @model.base_rosters_on_date(team_ids: [team_id], date:).pluck("player_id")

    unless RosterContinuity.roster_has_continuity?(players:, base_players:, date:)
      return Rs.new(rt:, rg: rt, r: 0, rb: 0)
    end

    base_players_ratings = @model.players_ratings_on_date(players: base_players, date:).pluck("rating")

    r = calculate_r
    rb = calculate_rt(base_players_ratings)
    rg = calculate_rg(r, rt, rb)

    Rs.new(rt:, rg:, r:, rb:)
  end

  def calculate_rt(player_ratings)
    ratings = player_ratings.sort.reverse
    raw_rt = 6.downto(1).sum { |i| i * (ratings[6 - i] || 0) / 6.0 }
    Integer(@q * raw_rt)
  end

  def calculate_r
    team_rating = @model.teams_ranking(team_ids: [team_id], date:)
    return 0 if team_rating.empty?

    team_rating[team_id].first["rating"]
  end

  def calculate_rg(r, rt, rb)
    return rt if r == 0 || rb == 0

    rg = Float(r) * rt / rb
    Integer(rg.clamp(0.5 * r, [rt, r].max))
  end
end
