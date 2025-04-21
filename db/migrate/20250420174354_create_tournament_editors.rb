class CreateTournamentEditors < ActiveRecord::Migration[8.0]
  def change
    create_table :tournament_editors do |t|
      t.integer :tournament_id
      t.integer :player_id
      t.index [:tournament_id, :player_id], unique: true
      t.timestamps
    end
  end
end
