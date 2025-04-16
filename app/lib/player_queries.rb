# frozen_string_literal: true

module PlayerQueries
  include Cacheable

  PlayerTournament = Struct.new(:release_id, :id, :name, :date,
    :team_name, :team_id, :place, :flag,
    :rating, :rating_change, :in_rating,
    keyword_init: true)

  PlayerOldTournament = Struct.new(:id, :name, :date,
    :team_name, :team_id, :place, :flag,
    :rating, :rating_change,
    keyword_init: true)

  PlayerRelease = Struct.new(:id, :date, :place, :rating, :rating_change, keyword_init: true)

  def player_tournaments(player_id:)
    sql = <<~SQL
      select rel.id as release_id, t.id as id, t.title as name, t.end_datetime as date,
          rr.team_title as team_name, rr.position as place, rr.team_id, tr.flag,
          rating.rating, rating.rating_change, rating.is_in_maii_rating as in_rating
      from #{name}.release rel
      left join public.tournaments t
          on t.end_datetime < rel.date + interval '24 hours' and t.end_datetime >= rel.date - interval '6 days'
      left join public.tournament_results rr
          on rr.tournament_id = t.id
      left join public.tournament_rosters tr
          on tr.tournament_id = t.id and tr.team_id = rr.team_id
      left join #{name}.tournament_result rating
          on rating.tournament_id = t.id and rating.team_id = rr.team_id
      where tr.player_id = $1
          and rr.position != 0
          and t.maii_rating = true
      order by t.end_datetime desc
    SQL

    exec_query(query: sql, params: [player_id], result_class: PlayerTournament)
  end

  def player_old_tournaments(player_id:)
    sql = <<~SQL
      select t.id as id, t.title as name, t.end_datetime as date,
          r.team_title as team_name, r.position as place, r.team_id, tr.flag,
          r.old_rating as rating, r.old_rating_delta as rating_change
      from public.tournaments t
      left join public.tournament_results r on r.tournament_id = t.id
      left join public.tournament_rosters tr on tr.tournament_id = t.id and tr.team_id = r.team_id
      where tr.player_id = $1
        and t.in_old_rating = true
        and t.end_datetime < '2021-09-01'
      order by t.end_datetime desc
    SQL

    exec_query(query: sql, params: [player_id], result_class: PlayerOldTournament)
  end

  def player_releases(player_id:)
    sql = <<~SQL
      select rel.id, rel.date, pr.place::integer, pr.rating, pr.rating_change
      from #{name}.release rel
      left join #{name}.player_rating pr on pr.player_id = $1 and pr.release_id = rel.id
      order by rel.date desc;
    SQL

    exec_query(query: sql, params: [player_id], result_class: PlayerRelease)
  end

  def player_rating_components(player_id:)
    sql = <<~SQL
      select r.cur_score as current,
        r.initial_score as initial,
        r.release_id,
        t.title as tournament_title,
        results.position
      from #{name}.player_rating_by_tournament r
      left join public.tournaments t
        on t.id = r.tournament_id
      left join public.tournament_rosters rosters
        on rosters.player_id = r.player_id and rosters.tournament_id = r.tournament_id
      left join public.tournament_results results
        on results.team_id = rosters.team_id and results.tournament_id = r.tournament_id
      where r.player_id = $1
      order by r.release_id, current desc
    SQL

    exec_query_for_hash(query: sql, params: [player_id], group_by: "release_id")
  end

  def players_ratings_on_date(players:, date:)
    placeholders = build_placeholders(start_with: 2, count: players.size)

    sql = <<~SQL
      select tr.player_id, tr.rating
      from #{name}.player_rating tr
      left join #{name}.release r on tr.release_id = r.id
      where r.date = $1 and tr.player_id IN (#{placeholders})
    SQL

    thursday = date.beginning_of_week(:thursday)
    exec_query_for_hash_array(query: sql, params: [thursday] + players)
  end
end
