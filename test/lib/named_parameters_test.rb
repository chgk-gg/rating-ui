# frozen_string_literal: true

require "test_helper"

class NamedParametersTest < ActiveSupport::TestCase
  test "converts simple named parameter to numbered" do
    query = "SELECT * FROM users WHERE id = :user_id"
    params = {user_id: 123}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "SELECT * FROM users WHERE id = $1", result_query
    assert_equal [123], result_params
  end

  test "converts multiple named parameters to numbered" do
    query = "SELECT * FROM users WHERE id = :user_id AND name = :user_name"
    params = {user_id: 123, user_name: "John"}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "SELECT * FROM users WHERE id = $1 AND name = $2", result_query
    assert_equal [123, "John"], result_params
  end

  test "handles repeated named parameters" do
    query = "SELECT * FROM users WHERE id = :user_id OR parent_id = :user_id"
    params = {user_id: 123}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "SELECT * FROM users WHERE id = $1 OR parent_id = $2", result_query
    assert_equal [123, 123], result_params
  end

  test "handles complex query with multiple repeated parameters" do
    query = "UPDATE teams SET rating = :rating WHERE id = :team_id OR parent_id = :team_id AND current_rating < :rating"
    params = {team_id: 456, rating: 1500}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "UPDATE teams SET rating = $1 WHERE id = $2 OR parent_id = $3 AND current_rating < $4", result_query
    assert_equal [1500, 456, 456, 1500], result_params
  end

  test "handles parameters with underscores" do
    query = "SELECT * FROM tournaments WHERE start_date = :start_date AND end_date = :end_date"
    params = {start_date: "2023-01-01", end_date: "2023-12-31"}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "SELECT * FROM tournaments WHERE start_date = $1 AND end_date = $2", result_query
    assert_equal %w[2023-01-01 2023-12-31], result_params
  end

  test "handles parameters with numbers" do
    query = "SELECT * FROM cache WHERE key1 = :cache_key1 AND key2 = :cache_key2"
    params = {cache_key1: "value1", cache_key2: "value2"}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "SELECT * FROM cache WHERE key1 = $1 AND key2 = $2", result_query
    assert_equal %w[value1 value2], result_params
  end

  test "handles nil parameter values" do
    query = "UPDATE users SET last_login = :last_login WHERE id = :user_id"
    params = {user_id: 123, last_login: nil}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "UPDATE users SET last_login = $1 WHERE id = $2", result_query
    assert_nil result_params[0]
    assert_equal 123, result_params[1]
  end

  test "returns original query and params when params is not a hash" do
    query = "SELECT * FROM users"
    params = []

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal query, result_query
    assert_equal params, result_params
  end

  test "returns original query and params when params is nil" do
    query = "SELECT * FROM users"
    params = nil

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal query, result_query
    assert_nil result_params
  end

  test "handles query with no named parameters" do
    query = "SELECT * FROM users WHERE active = true"
    params = {}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "SELECT * FROM users WHERE active = true", result_query
    assert_equal [], result_params
  end

  test "raises error for missing parameter" do
    query = "SELECT * FROM users WHERE id = :user_id AND name = :user_name"
    params = {user_id: 123}

    error = assert_raises(ArgumentError) do
      NamedParameters.convert_to_numbered(query, params)
    end
    assert_equal "Missing parameter: user_name", error.message
  end

  test "handles complex SQL with subqueries and joins" do
    query = <<~SQL
      SELECT u.*, t.name as team_name
      FROM users u
      LEFT JOIN teams t ON t.id = u.team_id
      WHERE u.created_at >= :start_date
        AND u.created_at <= :end_date
        AND (u.active = :active OR u.id IN (
          SELECT player_id FROM tournament_players WHERE tournament_id = :tournament_id
        ))
      ORDER BY u.rating DESC
      LIMIT :limit
    SQL
    params = {
      start_date: "2023-01-01",
      end_date: "2023-12-31",
      active: true,
      tournament_id: 42,
      limit: 100
    }

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    expected_query = <<~SQL
      SELECT u.*, t.name as team_name
      FROM users u
      LEFT JOIN teams t ON t.id = u.team_id
      WHERE u.created_at >= $1
        AND u.created_at <= $2
        AND (u.active = $3 OR u.id IN (
          SELECT player_id FROM tournament_players WHERE tournament_id = $4
        ))
      ORDER BY u.rating DESC
      LIMIT $5
    SQL

    assert_equal expected_query, result_query
    assert_equal ["2023-01-01", "2023-12-31", true, 42, 100], result_params
  end

  test "handles casting statements" do
    query = "SELECT * FROM players WHERE id = :player_id AND score::integer > :min_score"
    params = {player_id: 1, min_score: 100}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "SELECT * FROM players WHERE id = $1 AND score::integer > $2", result_query
    assert_equal [1, 100], result_params
  end

  test "handles parameters with single letter names" do
    query = "SELECT * FROM items WHERE x = :x AND y = :y AND z = :z"
    params = {x: 1, y: 2, z: 3}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "SELECT * FROM items WHERE x = $1 AND y = $2 AND z = $3", result_query
    assert_equal [1, 2, 3], result_params
  end

  test "maintains parameter order based on first occurrence" do
    query = "SELECT * FROM users WHERE (id = :user_id OR parent_id = :user_id) AND name = :name AND active = :active AND email LIKE :name"
    params = {user_id: 123, name: "John", active: true}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    expected_query = "SELECT * FROM users WHERE (id = $1 OR parent_id = $2) AND name = $3 AND active = $4 AND email LIKE $5"
    assert_equal expected_query, result_query
    assert_equal [123, 123, "John", true, "John"], result_params
  end

  test "handles empty parameter hash" do
    query = "SELECT COUNT(*) FROM users"
    params = {}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "SELECT COUNT(*) FROM users", result_query
    assert_equal [], result_params
  end

  test "handles parameters with leading underscores" do
    query = "SELECT * FROM temp_table WHERE _internal_id = :_internal_id"
    params = {_internal_id: 999}

    result_query, result_params = NamedParameters.convert_to_numbered(query, params)

    assert_equal "SELECT * FROM temp_table WHERE _internal_id = $1", result_query
    assert_equal [999], result_params
  end
end
