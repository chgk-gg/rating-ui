# frozen_string_literal: true

class MaterializedViewsJob < ApplicationJob
  queue_as :transform

  ViewDefinition = Data.define(:name, :query, :index_columns, :unique_index_columns)

  def perform(model)
    return if model.blank?

    @model = model
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET LOCAL statement_timeout TO 300000")
      definitions.each { |definition| create_or_refresh_view(definition) }
    end
  end

  private

  def create_or_refresh_view(definition)
    if view_exists?(definition)
      refresh_view(definition)
    else
      create_view(definition)
    end
  end

  def definitions
    [team_ranking]
  end

  def view_exists?(definition)
    query = <<~SQL
      select 1
      from pg_matviews
      where matviewname = '#{definition.name}'
        and schemaname = '#{@model}'
    SQL
    ActiveRecord::Base.connection.execute(query).any?
  end

  def create_view(definition)
    create_query = <<~SQL
      create materialized view if not exists #{@model}.#{definition.name}
      with (fillfactor = 90)
      as #{definition.query}
    SQL

    unique_index_query = <<~SQL
      create unique index if not exists #{definition.name}_unique_idx
      on #{@model}.#{definition.name} (#{definition.unique_index_columns.join(", ")})
    SQL

    index_queries = definition.index_columns.map do |column|
      index_name = "#{definition.name}_#{column}_idx"
      "create index if not exists #{index_name} on #{@model}.#{definition.name} (#{column})"
    end

    ActiveRecord::Base.connection.exec_query(create_query)
    ActiveRecord::Base.connection.exec_query(unique_index_query)
    index_queries.each { |query| ActiveRecord::Base.connection.exec_query(query) }
  end

  def refresh_view(definition)
    refresh_query = "refresh materialized view concurrently #{@model}.#{definition.name}"
    ActiveRecord::Base.connection.exec_query(refresh_query)
  end

  def team_ranking
    ViewDefinition.new(
      name: "team_ranking",
      index_columns: %w[team_id release_id place],
      unique_index_columns: %w[team_id release_id],
      query: <<~SQL
        select rank() over (partition by release_id order by rating desc) as place,
            team_id, rating, rating_change, release_id, trb
        from #{@model}.team_rating
      SQL
    )
  end
end
