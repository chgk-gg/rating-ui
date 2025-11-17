# frozen_string_literal: true

require "active_job/continuable"
require_relative "../lib/truedl_calculator"

class TrueDLForRecentTournamentsJob < ApplicationJob
  include ActiveJob::Continuable

  queue_as :wrappers

  def perform(model_name, days)
    model = Model.find_by(name: model_name)
    unless model
      Rails.logger.error "No model with the name #{model_name}"
      return
    end

    tournaments = Tournament.recent_tournaments(days)

    step :calculate do |step|
      tournaments.find_each(start: step.cursor, batch_size: 10) do |tournament|
        TrueDLCalculator.calculate_for_tournament(tournament_id: tournament.id, model_name:)
        step.advance! from: tournament.id
      end
    end
  end
end
