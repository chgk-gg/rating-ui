# frozen_string_literal: true

module ReleaseQueries
  include Cacheable

  ReleaseTeam = Struct.new(:team_id, :name, :city,
    :place, :previous_place, :rating, :rating_change,
    keyword_init: true)

  ReleasePlayer = Struct.new(:player_id, :name, :city,
    :place, :rating, :rating_change,
    keyword_init: true)

  Release = Struct.new(:id, :date, :q, keyword_init: true)

  def teams_for_release(release_id:, from:, to:, team_name: nil, city: nil)
    filtered = team_name.present? || city.present?
    sql = <<~SQL
      with ordered as (
          select id, row_number() over (order by date)
          from #{name}.release
      ),
      releases as (
          select o1.id as release_id, o2.id as prev_release_id
          from ordered o1
          left join ordered o2 on o1.row_number = o2.row_number + 1
      ),
      ranked as (
          select rank() over (order by rating desc) as place, team_id, rating, rating_change
          from #{name}.team_rating
          where release_id = $1
      ),
      ranked_prev_release as (
          select rank() over (order by rating desc) as place, team_id
          from #{name}.team_rating
          where release_id = (select prev_release_id from releases where release_id = $1)
      )

      select r.*, t.title as name, town.title as city, prev.place as previous_place
      from ranked r
      left join public.teams t on r.team_id = t.id
      left join public.towns town on town.id = t.town_id
      left join ranked_prev_release as prev using (team_id)
      #{"where t.title ilike $4 and town.title ilike $5" if filtered}
      order by r.place
      limit $2
      offset $3;
    SQL

    limit = to - from + 1
    offset = from - 1
    params = [release_id, limit, offset]
    params.append("%#{team_name}%", "%#{city}%") if filtered
    exec_query(query: sql, params:, result_class: ReleaseTeam, cache: !filtered)
  end

  def teams_for_release_api(release_id:, limit:, offset:)
    sql = <<~SQL
      with ordered as (
          select id, row_number() over (order by date)
          from #{name}.release
      ),
      releases as (
          select o1.id as release_id, o2.id as prev_release_id
          from ordered o1
          left join ordered o2 on o1.row_number = o2.row_number + 1
      )
      select r.*, prev.place as previous_place, r.place - prev.place as place_change
      from #{name}.team_ranking r
      left join #{name}.team_ranking prev
        on r.team_id = prev.team_id
          and prev.release_id = (select prev_release_id from releases where release_id = $1)
      where r.release_id = $1
      order by r.place, r.team_id
      limit $2
      offset $3;
    SQL

    exec_query_for_hash_array(query: sql, params: [release_id, limit, offset])
  end

  def teams_with_names_for_release_api(release_id:, limit:, offset:)
    sql = <<~SQL
      with ordered as (
          select id, row_number() over (order by date)
          from #{name}.release
      ),
      releases as (
          select o1.id as release_id, o2.id as prev_release_id
          from ordered o1
          left join ordered o2 on o1.row_number = o2.row_number + 1
      )
      select r.*, prev.place as previous_place, r.place - prev.place as place_change,
        t.title as team_name, towns.title as city
      from #{name}.team_ranking r
      left join #{name}.team_ranking prev
        on r.team_id = prev.team_id
          and prev.release_id = (select prev_release_id from releases where release_id = $1)
      left join public.teams t on t.id = r.team_id
      left join public.towns towns on t.town_id = towns.id
      where r.release_id = $1
      order by r.place, r.team_id
      limit $2
      offset $3;
    SQL

    exec_query_for_hash_array(query: sql, params: [release_id, limit, offset])
  end

  def tournaments_in_release_by_team(release_id:)
    sql = <<~SQL
      select t.id as tournament_id, tr.team_id, tr.rating, tr.rating_change, t.maii_rating as in_rating
      from #{name}.tournament_result tr
      left join public.tournaments t on tr.tournament_id = t.id
      left join #{name}.release rel
        on t.end_datetime < rel.date + interval '24 hours' and t.end_datetime >= rel.date - interval '6 days'
      where rel.id = $1
    SQL

    exec_query_for_hash(query: sql, params: [release_id], group_by: "team_id")
  end

  def tournaments_by_release
    sql = <<~SQL
      select t.id as id, t.maii_rating as in_rating, rel.id as release_id
      from public.tournaments t
      join #{name}.release rel
        on t.end_datetime < rel.date + interval '24 hours' and t.end_datetime >= rel.date - interval '6 days'
    SQL

    exec_query_for_hash(query: sql, group_by: "release_id")
  end

  def all_releases
    sql = <<~SQL
      select date, id, updated_at, q
      from #{name}.release
      order by date desc
    SQL

    exec_query_for_hash_array(query: sql, cache: true)
  end

  def latest_release_id
    sql = <<~SQL
        with team_count as (
          select r.id, r.date, count(tr.team_id)
          from #{name}.release r
          left join #{name}.team_rating tr on tr.release_id = r.id
          where r.date < now()
          group by r.id, r.date
      )

        select id
        from #{name}.release
        where date = (select max(date) from team_count where count > 0)
    SQL

    exec_query_for_single_value(query: sql)
  end

  def count_all_teams_in_release(release_id:, team_name: nil, city: nil)
    filtered = team_name.present? || city.present?
    filter_clause = "and t.title ilike $2 and town.title ilike $3"
    query = <<~SQL
      select count(*)
      from #{name}.team_rating tr
      left join public.teams t on t.id = tr.team_id
      left join public.towns town on town.id = t.town_id
      where tr.release_id = $1
      #{filter_clause if filtered}
    SQL

    params = [release_id]
    params.append("%#{team_name}%", "%#{city}%") if filtered
    exec_query_for_single_value(query:, params:, default_value: 0, cache: !filtered)
  end

  def players_for_release(release_id:, from:, to:, first_name: nil, last_name: nil)
    filtered_by_names = first_name.present? || last_name.present?
    first_name_clause = "p.first_name ilike :first_name" if first_name.present?
    last_name_clause = "p.last_name ilike :last_name" if last_name.present?
    names_where_clause = [first_name_clause, last_name_clause].compact.join(" and ")

    sql = <<~SQL
      with ranked as (
        select rank() over (order by rating desc) as place, player_id, rating, rating_change
        from #{name}.player_rating
        where release_id = :release_id
      )

      select r.*, p.first_name || '&nbsp;' || last_name as name
      from ranked r
      left join public.players p on p.id = r.player_id
      #{"where" if filtered_by_names}
      #{names_where_clause}
      order by r.place
      limit :limit
      offset :offset;
    SQL

    params = {release_id:, limit: to - from + 1, offset: from - 1}
    params[:first_name] = "%#{first_name}%" if first_name.present?
    params[:last_name] = "%#{last_name}%" if last_name.present?

    exec_query(query: sql, params:, result_class: ReleasePlayer, cache: !filtered_by_names)
  end

  def player_ratings_components_for_release(release_id:, player_ids:)
    placeholders = build_placeholders(start_with: 2, count: player_ids.size)
    player_filter = "and player_id in (#{placeholders})"

    sql = <<~SQL
      select player_id, tournament_id,
          cur_score as current_rating, initial_score as initial_rating
      from #{name}.player_rating_by_tournament
      where release_id = $1 #{player_filter unless player_ids.empty?}
    SQL

    exec_query_for_hash(query: sql, params: [release_id] + player_ids, group_by: "player_id")
  end

  def players_for_release_api(release_id:, limit:, offset:)
    sql = <<~SQL
      with ordered as (
          select id, row_number() over (order by date)
          from #{name}.release
      ),
      releases as (
          select o1.id as release_id, o2.id as prev_release_id
          from ordered o1
          left join ordered o2 on o1.row_number = o2.row_number + 1
      )

      select r.release_id, r.player_id, r.rating, r.rating_change, r.place::integer, 
          prev.place::integer as previous_place, 
          r.place::integer - prev.place::integer as place_change
      from #{name}.player_rating r
      left join #{name}.player_rating prev
        on r.player_id = prev.player_id
            and prev.release_id = (select prev_release_id from releases where release_id = $1)
      where r.release_id = $1
      order by r.place, r.player_id
      limit $2
      offset $3;
    SQL

    exec_query_for_hash_array(query: sql, params: [release_id, limit, offset])
  end

  def players_with_names_for_release_api(release_id:, limit:, offset:)
    sql = <<~SQL
      with ordered as (
          select id, row_number() over (order by date)
          from #{name}.release
      ),
      releases as (
          select o1.id as release_id, o2.id as prev_release_id
          from ordered o1
          left join ordered o2 on o1.row_number = o2.row_number + 1
      )

      select r.release_id, r.player_id, r.rating, r.rating_change, r.place::integer,
        prev.place::integer as previous_place,
        (r.place::integer - prev.place::integer) as place_change,
        p.first_name || ' ' || p.last_name as name
      from #{name}.player_rating r
      left join #{name}.player_rating prev
        on r.player_id = prev.player_id
          and prev.release_id = (select prev_release_id from releases where release_id = $1)
      left join public.players p 
        on p.id = r.player_id
      where r.release_id = $1
      order by r.place, r.player_id
      limit $2
      offset $3;
    SQL

    exec_query_for_hash_array(query: sql, params: [release_id, limit, offset])
  end

  def count_all_players_in_release(release_id:, first_name: nil, last_name: nil)
    filtered_by_names = first_name.present? || last_name.present?
    filter_clause = "and p.first_name ilike $2 and p.last_name ilike $3"
    query = <<~SQL
      select count(*)
      from #{name}.player_rating pr
      left join public.players p on p.id = pr.player_id
      where release_id = $1
      #{filter_clause if filtered_by_names}
    SQL

    params = [release_id]
    params.append("%#{first_name}%", "%#{last_name}%") if filtered_by_names
    exec_query_for_single_value(query:, params:, default_value: 0, cache: !filtered_by_names)
  end

  def release_for_date(date)
    sql = <<~SQL
      select id, date, q
      from #{name}.release
      where date = $1
    SQL

    thursday = date.beginning_of_week(:thursday)
    exec_query(query: sql, params: [thursday], cache: true, result_class: Release).first
  end
end
