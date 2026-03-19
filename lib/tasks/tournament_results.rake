namespace :tournament_results do
  desc "Fetch results for all tournaments a team has participated in"
  task :fetch_for_team, [:team_id] => :environment do |_t, args|
    abort "Usage: rake tournament_results:fetch_for_team[team_id]" unless args[:team_id]

    tournament_ids = TournamentResult.where(team_id: args[:team_id]).distinct.pluck(:tournament_id)

    if tournament_ids.empty?
      puts "No tournaments found for team #{args[:team_id]}"
      next
    end

    puts "Found #{tournament_ids.size} tournaments for team #{args[:team_id]}: #{tournament_ids.join(', ')}"

    tournament_ids.each do |tournament_id|
      SingleTournamentResultsJob.perform_later(tournament_id)
    end

    puts "Enqueued #{tournament_ids.size} SingleTournamentResultsJob jobs"
  end
end
