class AddUniqueIndexToTowns < ActiveRecord::Migration[8.0]
  def change
    add_index :towns, :id, unique: true
  end
end
