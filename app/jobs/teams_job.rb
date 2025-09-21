# frozen_string_literal: true

require "active_job/continuable"

class TeamsJob < ApplicationJob
  include ActiveJob::Continuable

  queue_as :chgk_info_import
  limits_concurrency to: 1, key: :chgk_info_api

  attr_reader :api_client

  def perform
    @api_client = ChgkInfo::APIClient.new

    step :fetch_page, start: 1 do |step|
      loop do
        teams = @api_client.teams(page: step.cursor)
        break if teams.empty?

        team_rows = teams.map do
          {
            id: it["id"],
            title: it["name"],
            town_id: it.dig("town", "id")
          }
        end

        ActiveRecord::Base.transaction do
          Team.upsert_all(team_rows)
        end

        step.set!(step.cursor + 1)
      end
    end
  end
end
