require_relative "../../app/lib/truedl_calculator"

namespace :true_dl do
  task :calculate_for_tournament, %i[id model] => :environment do |_t, args|
    TrueDLCalculator.calculate_for_tournament(tournament_id: args[:id], model_name: args[:model])
  end

  task :calculate_for_all_maii_tournaments, [:model] => :environment do |_t, args|
    TrueDLCalculator.calculate_for_all_maii_tournaments(model_name: args[:model])
  end

  task :delete_all, [:model] => :environment do |_t, args|
    Model.find_by(name: args[:model]).true_dls.delete_all
  end
end
