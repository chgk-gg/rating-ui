class TournamentGameJury < ApplicationRecord
  self.table_name = "tournament_game_jury"

  belongs_to :tournament
  belongs_to :player
end
