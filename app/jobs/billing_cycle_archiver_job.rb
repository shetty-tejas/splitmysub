class BillingCycleArchiverJob < ApplicationJob
  queue_as :default

  def perform(months_old = 6)
    Rails.logger.info "Starting automatic billing cycle archiving for cycles older than #{months_old} months"

    archived_count = BillingCycleArchiverService.archive_old_cycles(months_old)

    Rails.logger.info "Completed automatic billing cycle archiving. Archived #{archived_count} cycles."

    archived_count
  rescue => e
    Rails.logger.error "Billing cycle archiving failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
