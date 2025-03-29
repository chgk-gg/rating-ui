require_relative "../lib/truedl_calculator"

class TrueDLForTournamentJob < ApplicationJob
  queue_as :default

  def perform(model_name, tournament_id)
    TrueDLCalculator.calculate_for_tournament(tournament_id:, model_name:)
  end
end
