def create_release(date)
  sql = <<~SQL
    INSERT INTO b.release (date, title, updated_at) VALUES ('#{date}', '#{date}', now())
  SQL
  ActiveRecord::Base.connection.execute(sql)
end

def create_team_rating(release_id:, team_id:, rating:, rating_change: 0)
  sql = <<~SQL
    INSERT INTO b.team_rating (release_id, team_id, rating, rating_change, trb) 
    VALUES (#{release_id}, #{team_id}, #{rating}, #{rating_change}, 0)
  SQL
  ActiveRecord::Base.connection.execute(sql)
end

def create_player_rating(release_id:, player_id:, rating:, place:, rating_change: 0, place_change: 0)
  sql = <<~SQL
    INSERT INTO b.player_rating (release_id, player_id, rating, rating_change, place, place_change)
    VALUES (#{release_id}, #{player_id}, #{rating}, #{rating_change}, #{place}, #{place_change})
  SQL
  ActiveRecord::Base.connection.execute(sql)
end

def create_tournament_rating(tournament_id:, team_id:, rating: 100)
  sql = <<~SQL
    INSERT INTO b.tournament_result (team_id, tournament_id, mp, bp, m, rating, d1, d2, rating_change, is_in_maii_rating, r, rb, rg, rt)
    VALUES (#{team_id}, #{tournament_id}, 0, 0, 0, #{rating}, 0, 0, 0, true, 0, 0, 0, 0)
  SQL
  ActiveRecord::Base.connection.execute(sql)
end
