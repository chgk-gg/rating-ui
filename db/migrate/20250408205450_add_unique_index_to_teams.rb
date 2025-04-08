class AddUniqueIndexToTeams < ActiveRecord::Migration[8.0]
  def change
    add_index :teams, :id, unique: true
  end
end
