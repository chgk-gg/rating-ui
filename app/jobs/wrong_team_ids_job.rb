# frozen_string_literal: true

class WrongTeamIdsJob < ApplicationJob
  queue_as :transform

  def perform
    WrongTeamIds::Exporter.run(with_start_date_after: 1.year.ago)
  end
end
