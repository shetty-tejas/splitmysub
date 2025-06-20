class BillingCycleManager
  attr_reader :project, :config

  def initialize(project)
    @project = project
    @config = BillingConfig.current
  end

  # Main orchestration methods
  def generate_upcoming_cycles
    return [] unless config.auto_generation_enabled

    end_date = config.generation_end_date
    existing_cycles = project.billing_cycles.where("due_date <= ?", end_date)

    cycles_to_generate = calculate_missing_cycles(end_date, existing_cycles)
    created_cycles = []

    cycles_to_generate.each do |cycle_data|
      cycle = project.billing_cycles.create!(
        due_date: cycle_data[:due_date],
        total_amount: cycle_data[:total_amount],
        archived: false
      )
      created_cycles << cycle
    end

    created_cycles
  end

  def archive_old_cycles
    return 0 unless config.auto_archiving_enabled

    archivable_cycles = project.billing_cycles.where(
      "due_date < ? AND archived = ?",
      config.archiving_cutoff_date,
      false
    )

    count = 0
    archivable_cycles.find_each do |cycle|
      if config.is_archivable?(cycle)
        cycle.update!(archived: true)
        count += 1
      end
    end

    count
  end

  def get_due_soon_cycles
    project.billing_cycles.where(
      "due_date <= ? AND due_date >= ? AND archived = ?",
      config.due_soon_days.days.from_now.to_date,
      Date.current,
      false
    ).order(:due_date)
  end

    def get_overdue_cycles
    grace_cutoff = config.payment_grace_period_days.days.ago.to_date

    project.billing_cycles.where(
      "due_date < ? AND archived = ?",
      grace_cutoff,
      false
    ).where.not(
      id: project.payments.select(:billing_cycle_id).where("payments.created_at >= ?", grace_cutoff)
    ).order(:due_date)
  end

  def calculate_next_due_date(from_date = Date.current, frequency = nil)
    # Use project's frequency if not specified, fall back to config default
    frequency ||= project.billing_cycle || config.default_frequency

    case frequency.to_s
    when "daily"
      from_date + 1.day
    when "weekly"
      from_date + 1.week
    when "monthly"
      from_date + 1.month
    when "quarterly"
      from_date + 3.months
    when "yearly"
      from_date + 1.year
    else
      from_date + 1.month # fallback to monthly
    end
  end

    def calculate_total_amount_for_cycle(due_date)
    # For now, simple calculation: return project cost
    # This could be made more sophisticated with different pricing rules
    # and membership-based calculations
    project.cost || 0
  end

  def process_cycle_reminders
    reminder_cycles = []

    config.reminder_days_before.each do |days_before|
      reminder_date = days_before.days.from_now.to_date

      cycles_due = project.billing_cycles.where(
        due_date: reminder_date,
        archived: false
      )

      cycles_due.each do |cycle|
        if should_send_reminder?(cycle, days_before)
          reminder_cycles << { cycle: cycle, days_before: days_before }
        end
      end
    end

    reminder_cycles
  end

  def get_cycle_statistics
    {
      total_cycles: project.billing_cycles.count,
      active_cycles: project.billing_cycles.where(archived: false).count,
      archived_cycles: project.billing_cycles.where(archived: true).count,
      due_soon_count: get_due_soon_cycles.count,
      overdue_count: get_overdue_cycles.count,
      upcoming_cycles: project.billing_cycles.where("due_date > ? AND archived = ?", Date.current, false).count,
      next_generation_date: config.generation_end_date,
      next_archiving_cutoff: config.archiving_cutoff_date
    }
  end

  # Integration with existing services
  def sync_with_existing_generator
    # For backward compatibility, mirror BillingCycleGeneratorService behavior
    BillingCycleGeneratorService.generate_upcoming_cycles(project)
  rescue => e
    Rails.logger.error "BillingCycleManager: Error syncing with generator: #{e.message}"
    []
  end

  def sync_with_existing_archiver
    # For backward compatibility, mirror BillingCycleArchiverService behavior
    BillingCycleArchiverService.archive_old_cycles(project)
  rescue => e
    Rails.logger.error "BillingCycleManager: Error syncing with archiver: #{e.message}"
    0
  end

  # Validation and checks
  def validate_cycle_data(cycle_data)
    errors = []

    errors << "Due date is required" if cycle_data[:due_date].blank?
    errors << "Total amount must be non-negative" if cycle_data[:total_amount].to_f < 0
    errors << "Due date cannot be in the past" if cycle_data[:due_date].present? && cycle_data[:due_date] < Date.current

    if cycle_data[:due_date].present?
      existing = project.billing_cycles.where(due_date: cycle_data[:due_date]).exists?
      errors << "Billing cycle already exists for this due date" if existing
    end

    errors
  end

  def can_generate_cycles?
    config.auto_generation_enabled && project.present?
  end

  def can_archive_cycles?
    config.auto_archiving_enabled && project.present?
  end

  # Configuration helpers
  def current_configuration
    config.to_configuration_hash
  end

    def update_project_frequency(frequency)
    return false unless config.supports_frequency?(frequency)

    # Update the existing billing_cycle field in the project
    project.update(billing_cycle: frequency)
  end

  # New method to get the project's billing frequency
  def project_billing_frequency
    project.billing_cycle || config.default_frequency
  end

  # Enhanced method to validate frequency compatibility
  def can_use_frequency?(frequency)
    config.supports_frequency?(frequency) && project.can_use_frequency?(frequency)
  end

  # Method to update project frequency through the manager
  def update_project_frequency!(frequency)
    return false unless can_use_frequency?(frequency)

    project.update_billing_frequency!(frequency)
  end

  # Get frequency-specific generation settings
  def frequency_generation_settings
    frequency = project_billing_frequency

    {
      frequency: frequency,
      period_days: project.billing_period_days,
      cycles_per_generation_period: calculate_cycles_per_generation_period(frequency),
      max_cycles_to_generate: calculate_max_cycles_for_frequency(frequency)
    }
  end

  private

  def calculate_missing_cycles(end_date, existing_cycles)
    cycles_to_generate = []
    existing_due_dates = existing_cycles.pluck(:due_date).to_set
    frequency = project_billing_frequency

    # Start from the latest existing cycle or current date
    start_date = existing_cycles.maximum(:due_date) || Date.current
    current_date = start_date

    # Generate cycles until we reach the end_date
    while current_date <= end_date
      next_due_date = calculate_next_due_date(current_date, frequency)

      # Only add if this due date doesn't already exist
      unless existing_due_dates.include?(next_due_date)
        cycles_to_generate << {
          due_date: next_due_date,
          total_amount: calculate_total_amount_for_cycle(next_due_date)
        }
        existing_due_dates.add(next_due_date)
      end

      current_date = next_due_date

      # Safety break to prevent infinite loops (especially for daily/weekly cycles)
      max_cycles = calculate_max_cycles_for_frequency(frequency)
      break if cycles_to_generate.length > max_cycles
    end

    cycles_to_generate
  end

  def should_send_reminder?(cycle, days_before)
    # Check if reminder was already sent
    # This would integrate with your reminder tracking system
    # For now, simple check based on whether we have recent reminders

    recent_reminders = cycle.reminder_schedules.where(
      "created_at >= ? AND reminder_type = ?",
      1.day.ago,
      "#{days_before}_day_reminder"
    )

    recent_reminders.empty?
  rescue
    # If reminder_schedules relationship doesn't exist, assume we should send
    true
  end

  # Calculate how many cycles we should generate based on frequency
  def calculate_cycles_per_generation_period(frequency)
    generation_months = config.generation_months_ahead

    case frequency.to_s
    when "daily"
      generation_months * 30 # Approximate days per month
    when "weekly"
      generation_months * 4 # Approximate weeks per month
    when "monthly"
      generation_months
    when "quarterly"
      (generation_months / 3.0).ceil
    when "yearly"
      (generation_months / 12.0).ceil
    else
      generation_months # Default to monthly
    end
  end

  # Safety limit for cycle generation based on frequency
  def calculate_max_cycles_for_frequency(frequency)
    case frequency.to_s
    when "daily"
      200 # Max 200 daily cycles
    when "weekly"
      52 # Max 52 weekly cycles (1 year)
    when "monthly"
      24 # Max 24 monthly cycles (2 years)
    when "quarterly"
      12 # Max 12 quarterly cycles (3 years)
    when "yearly"
      5 # Max 5 yearly cycles
    else
      24 # Default to monthly limit
    end
  end
end
