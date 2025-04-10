# frozen_string_literal: true

class MaterializedViews
  ViewDefinition = Struct.new("ViewDefinition", :name, :query, :index_columns, keyword_init: true)

  def self.recreate_all(model:)
    return if model.blank?

    MaterializedViews.new(model).recreate_all
  end

  def initialize(model)
    @model = model
  end

  def recreate_all
    increase_statement_timeout!
    definitions.each { |definition| create_or_refresh_view(definition) }
    decrease_statement_timeout!
  end

  private

  def increase_statement_timeout!
    ActiveRecord::Base.connection.execute("SET statement_timeout TO 300000;")
  end

  def decrease_statement_timeout!
    default_timeout = ENV.fetch("DATABASE_STATEMENT_TIMEOUT", 5000)
    ActiveRecord::Base.connection.execute("SET statement_timeout TO #{default_timeout};")
  end

  def definitions
    [player_ranking, team_ranking]
  end

  def create_or_refresh_view(definition)
    create_query = <<~SQL
      create materialized view if not exists #{@model}.#{definition.name}
      as #{definition.query}
      with no data
    SQL
    refresh_query = "refresh materialized view #{@model}.#{definition.name}"
    index_queries = definition.index_columns.map do |column|
      index_name = "#{definition.name}_#{column}_idx"
      "create index if not exists #{index_name} on #{@model}.#{definition.name} (#{column})"
    end

    ActiveRecord::Base.connection.exec_query(create_query)
    ActiveRecord::Base.connection.exec_query(refresh_query)
    index_queries.each { |query| ActiveRecord::Base.connection.exec_query(query) }
  end

  def player_ranking
    ViewDefinition.new(
      name: "player_ranking",
      index_columns: %w[player_id release_id place],
      query: <<~SQL
        select rank() over (partition by release_id order by rating desc) as place,
            player_id, rating, rating_change, release_id
        from #{@model}.player_rating
      SQL
    )
  end

  def team_ranking
    ViewDefinition.new(
      name: "team_ranking",
      index_columns: %w[team_id release_id place],
      query: <<~SQL
        select rank() over (partition by release_id order by rating desc) as place,
            team_id, rating, rating_change, release_id, trb
        from #{@model}.team_rating
      SQL
    )
  end
end
