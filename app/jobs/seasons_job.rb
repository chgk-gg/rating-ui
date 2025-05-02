# frozen_string_literal: true

class SeasonsJob < ApplicationJob
  queue_as :chgk_info_import
  limits_concurrency to: 1, key: :chgk_info_api

  def perform
    seasons = ChgkInfo::APIClient.new.seasons.map do
      {
        id: it["id"],
        start: it["dateStart"][0...10],
        end: it["dateEnd"][0...10]
      }
    end

    Season.upsert_all(seasons, unique_by: %i[id])
  end
end
