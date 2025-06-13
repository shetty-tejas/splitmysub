class BillingCycleNotificationJob < ApplicationJob
  queue_as :default

  def perform(project_id, billing_cycle_ids)
    project = Project.find(project_id)
    billing_cycles = BillingCycle.where(id: billing_cycle_ids)

    return if billing_cycles.empty?

    # Send email to project owner
    BillingCycleMailer.new_cycles_created(project, billing_cycles).deliver_now

    Rails.logger.info "Sent billing cycle notification to #{project.user.email_address} for project #{project.name}"
  rescue => e
    Rails.logger.error "Failed to send billing cycle notification for project #{project_id}: #{e.message}"
  end
end
