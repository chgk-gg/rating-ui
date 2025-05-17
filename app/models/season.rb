class Season < ApplicationRecord
  self.primary_key = "id"

  FIRST_MAII_SEASON_START = Date.new(2021, 9, 1)

  def self.current_season
    Rails.cache.fetch("current_season", expires_in: 12.hours) do
      Season.find_by('current_date between "start" and "end"')
    end
  end

  def title
    "#{start.strftime("%Y")}/#{self.end.strftime("%y")}"
  end
end
