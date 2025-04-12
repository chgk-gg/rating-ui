# frozen_string_literal: true

require "test_helper"

class MaterializedViewsJobTest < ActiveSupport::TestCase
  def setup
    @schema = "test_schema"
    @connection = ActiveRecord::Base.connection

    @connection.execute("CREATE SCHEMA IF NOT EXISTS #{@schema}")

    @connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{@schema}.player_rating (
        player_id integer,
        rating numeric,
        rating_change numeric,
        release_id integer
      )
    SQL

    @connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{@schema}.team_rating (
        team_id integer,
        rating numeric,
        rating_change numeric,
        release_id integer,
        trb numeric
      )
    SQL

    @connection.execute("DROP MATERIALIZED VIEW IF EXISTS #{@schema}.player_ranking")
    @connection.execute("DROP MATERIALIZED VIEW IF EXISTS #{@schema}.team_ranking")
  end

  def teardown
    @connection.execute("DROP SCHEMA IF EXISTS #{@schema} CASCADE")
  end

  def test_perform_creates_materialized_views
    MaterializedViewsJob.perform_now(@schema)

    assert view_exists?("player_ranking"), "player_ranking view was not created"
    assert view_exists?("team_ranking"), "team_ranking view was not created"

    assert_columns_exist("player_ranking", %w[place player_id rating rating_change release_id])
    assert_columns_exist("team_ranking", %w[place team_id rating rating_change release_id trb])

    %w[player_id release_id place].each do |column|
      index_name = "player_ranking_#{column}_idx"
      assert index_exists?("player_ranking", index_name), "Index #{index_name} should exist"
    end

    %w[team_id release_id place].each do |column|
      index_name = "team_ranking_#{column}_idx"
      assert index_exists?("team_ranking", index_name), "Index #{index_name} should exist"
    end
  end

  private

  def assert_columns_exist(view_name, expected_columns)
    query = <<~SQL
      SELECT #{expected_columns.join(", ")}
      FROM #{@schema}.#{view_name}
    SQL

    @connection.execute(query)
  end

  def view_exists?(view_name)
    query = <<~SQL
      SELECT EXISTS (
        SELECT FROM pg_matviews
        WHERE matviewname = '#{view_name}'
        AND schemaname = '#{@schema}'
      )
    SQL
    @connection.select_value(query)
  end

  def index_exists?(view_name, index_name)
    query = <<~SQL
      SELECT EXISTS (
        SELECT FROM pg_indexes
        WHERE schemaname = '#{@schema}'
        AND tablename = '#{view_name}'
        AND indexname = '#{index_name}'
      )
    SQL
    @connection.select_value(query)
  end
end
