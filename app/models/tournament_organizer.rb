class TournamentOrganizer < ApplicationRecord
  belongs_to :tournament
  belongs_to :player
end
