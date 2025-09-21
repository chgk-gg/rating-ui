# frozen_string_literal: true

require "active_job/continuable"

class PlayersJob < ApplicationJob
  include ActiveJob::Continuable

  queue_as :chgk_info_import
  limits_concurrency to: 1, key: :chgk_info_api

  attr_reader :api_client

  def perform
    @api_client = ChgkInfo::APIClient.new

    step :fetch_page, start: 1 do |step|
      loop do
        players = @api_client.players(page: step.cursor)
        break if players.empty?

        player_rows = players.map do
          {
            id: it["id"],
            first_name: it["name"],
            patronymic: it["patronymic"],
            last_name: it["surname"],
            date_died: it["dateDied"],
            got_questions_tag: it["gotQuestionsTag"]
          }
        end

        ActiveRecord::Base.transaction do
          Player.upsert_all(player_rows)
        end

        step.set!(step.cursor + 1)
      end
    end
  end
end
