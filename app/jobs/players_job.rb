# frozen_string_literal: true

class PlayersJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :chgk_info_api

  attr_reader :api_client

  def perform
    @api_client = ChgkInfo::APIClient.new

    page_number = 1
    players = fetch_page(page_number)

    while players.size > 0
      player_rows = players.map do
        {
          id: player["id"],
          first_name: player["name"],
          patronymic: player["patronymic"],
          last_name: player["surname"]
        }
      end

      ActiveRecord::Base.transaction do
        Player.upsert_all(player_rows)
      end

      page_number += 1
      players = fetch_page(page_number)
    end
  end

  def fetch_page(page)
    @api_client.players(page:)
  end
end
