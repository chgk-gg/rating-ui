class WrongTeamIdsJob < ApplicationJob
  queue_as :transform
  queue_with_priority LOW_PRIORITY

  def perform
    WrongTeamIds::Exporter.run(with_start_date_after: 1.year.ago)
  end
end
