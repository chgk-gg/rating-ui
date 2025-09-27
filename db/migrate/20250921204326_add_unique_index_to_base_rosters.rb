class AddUniqueIndexToBaseRosters < ActiveRecord::Migration[8.1]
  def change
    add_index :base_rosters, [:season_id, :team_id, :player_id], unique: true
  end
end
