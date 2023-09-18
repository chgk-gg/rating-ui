# frozen_string_literal: true

module TournamentQueries
  include Cacheable

  TournamentResults = Struct.new(:team_id, :team_name, :team_city,
                                 :place, :points,
                                 :rating, :rating_change, :in_rating,
                                 :predicted_rating, :predicted_place,
                                 :d1, :d2, :players,
                                 keyword_init: true)

  TournamentPageDetails = Struct.new(:name, :start, :end, :maii_rating)

  TournamentListDetails = Struct.new(:id, :name, :type, :date, :rating, keyword_init: true)

  def tournament_results(tournament_id:)
    sql = <<~SQL
      select r.position as place, r.total as points,
          r.team_title as team_name, r.team_id,
          t.title as team_city,
          tr.rating as rating, tr.rating_change as rating_change,
          tr.is_in_maii_rating as in_rating,
          tr.bp as predicted_rating, tr.d1, tr.d2,
          tr.mp as predicted_place
      from public.tournament_results r
      left join #{name}.tournament_result tr
          on r.team_id = tr.team_id and tr.tournament_id = $1
      left join public.towns t on r.team_city_id = t.id
      where r.tournament_id = $1
      order by position, r.team_id
    SQL

    exec_query(query: sql, params: [tournament_id], result_class: TournamentResults)
  end

  def tournament_ratings(tournament_id:)
    sql = <<~SQL
      select team_id,
          rating, rating_change,
          is_in_maii_rating as in_rating,
          bp as forecast, mp::real as place_forecast,
          d1, d2, r, rb, rg, rt
      from #{name}.tournament_result
      where tournament_id = $1
      order by rating desc
    SQL

    exec_query_for_hash_array(query: sql, params: [tournament_id])
  end

  def tournament_ratings_with_team_names(tournament_id:)
    sql = <<~SQL
      select tr.team_id,
          rating, rating_change,
          is_in_maii_rating as in_rating,
          bp as forecast, mp::real as place_forecast,
          d1, d2, r, rb, rg, rt,
          t.title as base_team_name,
          public_tr.team_title as team_name,
          towns.title as city
      from #{name}.tournament_result tr
      left join public.tournament_results public_tr using (team_id, tournament_id)
      left join public.teams t on tr.team_id = t.id
      left join public.towns towns on public_tr.team_city_id = towns.id
      where tournament_id = $1
      order by rating desc
    SQL

    exec_query_for_hash_array(query: sql, params: [tournament_id])
  end

  def tournament_players(tournament_id:)
    sql = <<~SQL
      select tr.team_id, tr.player_id,
          p.first_name || '&nbsp;' || last_name as name,
          tr.flag
      from public.tournament_rosters tr
      left join public.players p on tr.player_id = p.id
      where tr.tournament_id = $1
      order by tr.team_id, tr.flag, p.last_name
    SQL

    exec_query_for_hash(query: sql, params: [tournament_id], group_by: 'team_id')
  end

  def tournament_details(tournament_id:)
    sql = <<~SQL
      select t.title as name, start_datetime, end_datetime, maii_rating
      from public.tournaments t
      where t.id = $1
    SQL

    row = exec_query_for_single_row(query: sql, params: [tournament_id])
    TournamentPageDetails.new(*row)
  end

  def tournaments_list
    sql = <<~SQL
      with winners as (
          select tr.tournament_id, max(rating) as max_rating
          from #{name}.tournament_result tr
          group by tr.tournament_id
      )

      select t.id, t.title as name, t.type, t.end_datetime as date,
             w.max_rating as rating
      from public.tournaments t
      left join winners w on t.id = w.tournament_id
      where t.maii_rating = true
        and t.end_datetime <= now() + interval '1 month'
      order by date desc
    SQL

    exec_query(query: sql, result_class: TournamentListDetails)
  end
end
