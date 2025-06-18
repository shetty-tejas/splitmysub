class BillingArchivePolicy
  attr_reader :config, :project

  def initialize(config, project = nil)
    @config = config
    @project = project
  end

  # Main policy decision: should we archive cycles?
  def should_archive_cycles?
    config.auto_archiving_enabled && project.present?
  end

  # Get the cutoff date for archiving
  def archiving_cutoff_date
    config.archiving_cutoff_date
  end

  # Determine if a specific cycle should be archived
  def should_archive_cycle?(cycle)
    return false unless should_archive_cycles?
    return false if cycle.archived?
    return false unless cycle.due_date < archiving_cutoff_date

    # Additional business rules
    can_archive_with_payments?(cycle) && meets_archiving_criteria?(cycle)
  end

  # Get all cycles that should be archived
  def archivable_cycles
    return BillingCycle.none unless should_archive_cycles?

    candidate_cycles = project.billing_cycles.where(
      "due_date < ? AND archived = ?",
      archiving_cutoff_date,
      false
    )

    candidate_cycles.select { |cycle| should_archive_cycle?(cycle) }
  end

  # Count cycles that would be archived
  def archivable_cycles_count
    archivable_cycles.length
  end

  # Archive cycles and return count
  def archive_eligible_cycles!
    return 0 unless should_archive_cycles?

    cycles_to_archive = archivable_cycles
    archived_count = 0

    cycles_to_archive.each do |cycle|
      if perform_archive(cycle)
        archived_count += 1
      end
    end

    archived_count
  end

  # Validate archiving parameters
  def validate_archiving_rules
    errors = []

    errors << "Project is required for cycle archiving" unless project.present?
    errors << "Auto archiving is disabled" unless config.auto_archiving_enabled
    errors << "Archiving threshold must be positive" unless config.archiving_months_threshold > 0

    errors
  end

  # Check if a cycle can be safely archived
  def can_safely_archive?(cycle)
    return false unless should_archive_cycle?(cycle)

    # Business rules for safe archiving
    has_completed_payments?(cycle) &&
    no_pending_disputes?(cycle) &&
    meets_retention_requirements?(cycle)
  end

  # Get archiving summary for reporting
  def archiving_summary
    {
      enabled: should_archive_cycles?,
      cutoff_date: archiving_cutoff_date,
      eligible_count: archivable_cycles_count,
      validation_errors: validate_archiving_rules
    }
  end

  # Preview what would be archived (without actually archiving)
  def preview_archiving
    return [] unless should_archive_cycles?

    archivable_cycles.map do |cycle|
      {
        cycle_id: cycle.id,
        due_date: cycle.due_date,
        total_amount: cycle.total_amount,
        payment_status: cycle.payment_status,
        can_safely_archive: can_safely_archive?(cycle),
        archive_reason: archive_reason(cycle)
      }
    end
  end

  # Force archive a specific cycle (bypass some safety checks)
  def force_archive_cycle!(cycle, reason = nil)
    return false unless cycle.present?
    return false if cycle.archived?

    cycle.update!(
      archived: true,
      archived_at: Time.current,
      adjustment_reason: reason || "Force archived via policy"
    )
    true
  rescue => e
    Rails.logger.error "BillingArchivePolicy: Failed to force archive cycle #{cycle.id}: #{e.message}"
    false
  end

  # Unarchive a cycle if business rules allow
  def can_unarchive_cycle?(cycle)
    return false unless cycle.archived?
    return false if cycle.due_date < (Date.current - 1.year) # Too old to unarchive

    # Additional business rules for unarchiving
    true
  end

  def unarchive_cycle!(cycle, reason = nil)
    return false unless can_unarchive_cycle?(cycle)

    cycle.update!(
      archived: false,
      archived_at: nil,
      adjustment_reason: reason || "Unarchived via policy"
    )
    true
  rescue => e
    Rails.logger.error "BillingArchivePolicy: Failed to unarchive cycle #{cycle.id}: #{e.message}"
    false
  end

  private

  def can_archive_with_payments?(cycle)
    # Allow archiving if cycle is fully paid or overdue beyond grace period
    cycle.fully_paid? || cycle.due_date < (Date.current - config.payment_grace_period_days.days)
  end

  def meets_archiving_criteria?(cycle)
    # Additional business criteria for archiving
    # Could include: dispute resolution, audit requirements, etc.

    # For now, basic criteria
    cycle.due_date < archiving_cutoff_date
  end

  def perform_archive(cycle)
    return false unless should_archive_cycle?(cycle)

    cycle.update!(
      archived: true,
      archived_at: Time.current,
      adjustment_reason: "Auto-archived via policy - due date #{cycle.due_date}"
    )
    true
  rescue => e
    Rails.logger.error "BillingArchivePolicy: Failed to archive cycle #{cycle.id}: #{e.message}"
    false
  end

  def has_completed_payments?(cycle)
    # Check if payment collection is complete for this cycle
    cycle.fully_paid? || cycle.due_date < (Date.current - config.payment_grace_period_days.days)
  end

  def no_pending_disputes?(cycle)
    # Future enhancement: check for payment disputes
    # For now, assume no disputes
    true
  end

  def meets_retention_requirements?(cycle)
    # Future enhancement: check legal/compliance retention requirements
    # For now, assume requirements are met if beyond threshold
    cycle.due_date < archiving_cutoff_date
  end

  def archive_reason(cycle)
    if cycle.fully_paid?
      "Fully paid and beyond retention period"
    elsif cycle.due_date < (Date.current - config.payment_grace_period_days.days)
      "Overdue beyond grace period"
    else
      "Beyond archiving threshold"
    end
  end
end
