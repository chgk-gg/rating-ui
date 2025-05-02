class AddUniqueIndexToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_index :players, :id, unique: true
  end
end
