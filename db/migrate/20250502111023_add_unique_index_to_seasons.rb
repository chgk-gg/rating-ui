class AddUniqueIndexToSeasons < ActiveRecord::Migration[8.0]
  def change
    add_index :seasons, :id, unique: true
  end
end
