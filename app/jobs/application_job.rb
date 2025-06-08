class ApplicationJob < ActiveJob::Base
  around_perform do |job, block|
    ActiveRecord::Base.connected_to(role: :writing) do
      block.call
    end
  end
end
