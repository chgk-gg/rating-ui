require_relative "../lib/truedl_calculator"

class TrueDLForAllTournamentsJob < ApplicationJob
  queue_as :default

  def perform(model_name)
    TrueDLCalculator.calculate_for_all_tournaments_since_2021(model_name:)
  end
end
