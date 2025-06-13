class BillingCycleGeneratorJob < ApplicationJob
  queue_as :default

  def perform(months_ahead = 3)
    Rails.logger.info "Starting billing cycle generation for #{months_ahead} months ahead"

    generated_cycles = BillingCycleGeneratorService.generate_all_upcoming_cycles(months_ahead)

    Rails.logger.info "Generated #{generated_cycles.count} billing cycles"

    # Send notification to project owners about new billing cycles
    notify_project_owners(generated_cycles) if generated_cycles.any?

    generated_cycles
  end

  private

  def notify_project_owners(generated_cycles)
    # Group cycles by project
    cycles_by_project = generated_cycles.group_by(&:project)

    cycles_by_project.each do |project, cycles|
      begin
        BillingCycleNotificationJob.perform_later(project.id, cycles.map(&:id))
      rescue => e
        Rails.logger.error "Failed to schedule notification for project #{project.id}: #{e.message}"
      end
    end
  end
end
