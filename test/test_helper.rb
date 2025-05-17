# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "minitest"
require_relative "../config/environment"
require "rails/test_help"
require "capybara/rails"
require "capybara/minitest"
require_relative "factories"

Rails.root.glob("test/jobs/**/*_test.rb").each { require it }

class ActionDispatch::IntegrationTest
  include ActiveRecord::TestFixtures
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end

Capybara.default_driver = :rack_test

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.allow_http_connections_when_no_cassette = false
end

def count_queries(match_pattern = nil, &block)
  count = 0
  matching_queries = []

  counter_fn = ->(name, start, finish, id, payload) do
    sql = payload[:sql]
    if match_pattern.nil? || (match_pattern.is_a?(Regexp) ? sql.match?(match_pattern) : sql.include?(match_pattern))
      count += 1
      matching_queries << sql
    end
  end

  ActiveSupport::Notifications.subscribed(counter_fn, "sql.active_record") do
    yield
  end

  [count, matching_queries]
end

ModelIndexer.run
ActiveRecord::Base.connection.execute("DROP MATERIALIZED VIEW IF EXISTS b.team_ranking")
MaterializedViewsJob.perform_now(InModel::DEFAULT_MODEL)

ActiveRecord::Base.connection.execute("TRUNCATE b.release RESTART IDENTITY CASCADE")
ActiveRecord::Base.connection.execute("TRUNCATE b.team_rating RESTART IDENTITY CASCADE")
create_release("2024-09-05")
create_release("2024-09-12")
create_release("2024-09-19")

create_team_rating(release_id: 1, team_id: 2, rating: 14000)
create_team_rating(release_id: 1, team_id: 3, rating: 12100)
create_team_rating(release_id: 2, team_id: 2, rating: 14300, rating_change: 300)
create_team_rating(release_id: 2, team_id: 3, rating: 12000, rating_change: -100)
create_team_rating(release_id: 1, team_id: 7, rating: 7500)
create_team_rating(release_id: 2, team_id: 7, rating: 7500)
create_team_rating(release_id: 2, team_id: 25, rating: 8000)
