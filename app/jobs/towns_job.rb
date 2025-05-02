# frozen_string_literal: true

class TownsJob < ApplicationJob
  queue_as :chgk_info_import
  limits_concurrency to: 1, key: :chgk_info_api

  attr_reader :api_client

  def perform
    @api_client = ChgkInfo::APIClient.new

    page_number = 1
    towns = fetch_page(page_number)

    while towns.size > 0
      town_rows = towns.map do
        {
          id: it["id"],
          title: it["name"]
        }
      end

      ActiveRecord::Base.transaction do
        Town.upsert_all(town_rows)
      end

      page_number += 1
      towns = fetch_page(page_number)
    end
  end

  def fetch_page(page)
    @api_client.towns(page:)
  end
end
