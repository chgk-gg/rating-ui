class AddTwoFieldsToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :date_died, :date
    add_column :players, :got_questions_tag, :integer
  end
end
