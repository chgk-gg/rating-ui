class MachineDestructionJob < ApplicationJob
  queue_as :rating_calculation

  retry_on Fly::MachinesClient::Error, wait: :polynomially_longer, attempts: 5

  # With restart policy "no" the machine stops itself as soon as the script
  # exits, whatever the exit code; this removes the stopped machine.
  # A machine can only linger (stopped, costing nothing but rootfs)
  # if the worker process dies mid-poll.
  def perform(app_name, machine_id)
    Fly::MachinesClient.destroy_machine(app_name, machine_id)
    Rails.logger.info "destroyed machine #{machine_id}"
  end
end
