module TeamQueries
  include Cacheable

  TeamTournament = Struct.new(:release_id, :id, :name, :date, :place,
    :rating, :rating_change, :in_rating,
    keyword_init: true)

  TeamRelease = Struct.new(:id, :date, :place, :rating, :rating_change, keyword_init: true)

  def team_tournaments(team_id:)
    sql = <<~SQL
      select rel.id as release_id,
             t.id as id, t.title as name, t.end_datetime as date,
             r.position as place,
             tr.rating, tr.rating_change, tr.is_in_maii_rating as in_rating
      from #{name}.release rel
      left join public.tournaments t
          on t.end_datetime < rel.date + interval '24 hours' and t.end_datetime >= rel.date - interval '6 days'
      left join public.tournament_results r
          on r.tournament_id = t.id
      left join #{name}.tournament_result tr
          on tr.tournament_id = t.id and r.team_id = tr.team_id
      where r.team_id = $1
          and r.position != 0
          and t.maii_rating = true
      order by t.end_datetime desc;
    SQL

    exec_query(query: sql,
      params: [team_id],
      result_class: TeamTournament)
  end

  def team_releases(team_id:)
    sql = <<~SQL
      select rel.id, rel.date, ranking.place, ranking.rating, ranking.rating_change
      from #{name}.release rel
      left join #{name}.team_ranking ranking on ranking.team_id = $1 and ranking.release_id = rel.id
      order by rel.date desc;
    SQL

    exec_query(query: sql, params: [team_id], result_class: TeamRelease)
  end

  def teams_ranking(team_ids:, date:)
    placeholders = build_placeholders(start_with: 2, count: team_ids.size)

    sql = <<~SQL
      select tr.team_id, tr.place, tr.rating
      from b.team_ranking tr
      left join b.release r on tr.release_id = r.id
      where r.date = $1 and tr.team_id IN (#{placeholders})
    SQL

    thursday = date.beginning_of_week(:thursday)
    exec_query_for_hash(query: sql, params: [thursday] + team_ids, group_by: "team_id")
  end

  def base_rosters_on_date(team_ids:, date:)
    placeholders = build_placeholders(start_with: 2, count: team_ids.size)

    sql = <<~SQL
       select br.player_id, br.team_id, p.first_name || '&nbsp;' || p.last_name as name
       from public.base_rosters br
       left join public.players p on p.id = br.player_id
       left join public.seasons on br.season_id = seasons.id
       where $1 >= br.start_date
         and (br.end_date < $1 or br.end_date is null)
         and br.team_id in (#{placeholders})
         and $1 between seasons.start and seasons."end"
      order by p.last_name
    SQL

    exec_query_for_hash_array(query: sql, params: [date] + team_ids)
  end
end
