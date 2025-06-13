class BillingCycleArchiverService
  def self.archive_old_cycles(months_old = 6)
    new(months_old).archive_old_cycles
  end

  def initialize(months_old = 6)
    @months_old = months_old
    @cutoff_date = months_old.months.ago.to_date
  end

  def archive_old_cycles
    archived_count = 0

    # Use a dynamic query instead of the hardcoded archivable scope
    old_cycles = BillingCycle.where("due_date < ? AND archived = ?", @cutoff_date, false)

    old_cycles.find_each do |billing_cycle|
      if should_archive?(billing_cycle)
        billing_cycle.archive!
        archived_count += 1
        Rails.logger.info "Archived billing cycle #{billing_cycle.id} for project #{billing_cycle.project.name}"
      end
    end

    Rails.logger.info "Archived #{archived_count} old billing cycles"
    archived_count
  end

  private

  def should_archive?(billing_cycle)
    # Archive if the billing cycle is old enough and meets certain criteria
    return false if billing_cycle.archived?
    return false if billing_cycle.due_date >= @cutoff_date

    # Only archive if it's fully paid or has been overdue for a long time
    billing_cycle.fully_paid? || billing_cycle.due_date < 1.year.ago
  end
end
