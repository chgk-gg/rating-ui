namespace :solid_queue do
  desc "Clear pending jobs. Optionally specify a queue: rake solid_queue:clear[queue_name]"
  task :clear, [:queue] => :environment do |_t, args|
    if args[:queue]
      count = SolidQueue::Job.where(queue_name: args[:queue], finished_at: nil).count
      SolidQueue::Job.where(queue_name: args[:queue], finished_at: nil).destroy_all
      puts "Cleared #{count} pending job(s) from queue '#{args[:queue]}'."
    else
      count = SolidQueue::Job.where(finished_at: nil).count
      SolidQueue::Job.where(finished_at: nil).destroy_all
      puts "Cleared #{count} pending job(s) from all queues."
    end
  end
end
