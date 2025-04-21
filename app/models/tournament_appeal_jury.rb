class TournamentAppealJury < ApplicationRecord
  self.table_name = "tournament_appeal_jury"

  belongs_to :tournament
  belongs_to :player
end
