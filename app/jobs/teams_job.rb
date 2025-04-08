# frozen_string_literal: true

class TeamsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :chgk_info_api

  attr_reader :api_client

  def perform
    @api_client = ChgkInfo::APIClient.new

    page_number = 1
    teams = fetch_page(page_number)

    while teams.size > 0
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

      page_number += 1
      teams = fetch_page(page_number)
    end
  end

  def fetch_page(page)
    @api_client.teams(page:)
  end
end
