# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "minitest"
require_relative "../config/environment"
require "rails/test_help"
require "capybara/rails"
require "capybara/minitest"
require_relative "factories"

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

ModelIndexer.run
MaterializedViews.recreate_all(model: InModel::DEFAULT_MODEL)

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
