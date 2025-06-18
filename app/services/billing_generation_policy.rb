class BillingGenerationPolicy
  attr_reader :config, :project

  def initialize(config, project = nil)
    @config = config
    @project = project
  end

  # Main policy decision: should we generate cycles?
  def should_generate_cycles?
    config.auto_generation_enabled && project_allows_generation?
  end

  # Calculate how many cycles to generate
  def cycles_to_generate
    return 0 unless should_generate_cycles?

    end_date = generation_end_date
    existing_cycles = project.billing_cycles.where("due_date <= ?", end_date)

    calculate_missing_cycles(end_date, existing_cycles).length
  end

  # Get the date until which we should generate cycles
  def generation_end_date
    config.generation_end_date
  end

  # Determine if a specific date needs a cycle
  def needs_cycle_for_date?(due_date)
    return false unless should_generate_cycles?
    return false if due_date < Date.current
    return false if due_date > generation_end_date

    # Check if cycle already exists for this date
    !project.billing_cycles.exists?(due_date: due_date)
  end

  # Calculate the next due date based on frequency
  def next_due_date(from_date = Date.current, frequency = nil)
    frequency ||= project_frequency || config.default_frequency

    case frequency.to_s.downcase
    when "daily"
      from_date + 1.day
    when "weekly"
      from_date + 1.week
    when "biweekly", "bi-weekly"
      from_date + 2.weeks
    when "monthly"
      from_date + 1.month
    when "quarterly"
      from_date + 3.months
    when "semi-annually", "semiannually"
      from_date + 6.months
    when "yearly", "annually"
      from_date + 1.year
    else
      # Default to monthly for unknown frequencies
      from_date + 1.month
    end
  end

  # Generate cycle data for a specific date
  def generate_cycle_data(due_date)
    return nil unless needs_cycle_for_date?(due_date)

    {
      due_date: due_date,
      total_amount: calculate_cycle_amount(due_date),
      archived: false,
      project: project
    }
  end

  # Get all missing cycles that should be generated
  def missing_cycles_data
    return [] unless should_generate_cycles?

    end_date = generation_end_date
    existing_cycles = project.billing_cycles.where("due_date <= ?", end_date)

    calculate_missing_cycles(end_date, existing_cycles)
  end

  # Validate generation parameters
  def validate_generation_rules
    errors = []

    errors << "Project is required for cycle generation" unless project.present?
    errors << "Auto generation is disabled" unless config.auto_generation_enabled
    errors << "Generation months ahead must be positive" unless config.generation_months_ahead > 0

    if project.present?
      errors << "Project has invalid billing frequency" unless valid_project_frequency?
      errors << "Project cost must be positive" unless project.cost.present? && project.cost > 0
    end

    errors
  end

  # Check if generation would create duplicate cycles
  def would_create_duplicates?(cycles_data)
    return false if cycles_data.empty?

    due_dates = cycles_data.map { |data| data[:due_date] }
    existing_count = project.billing_cycles.where(due_date: due_dates).count

    existing_count > 0
  end

  # Get generation summary for reporting
  def generation_summary
    {
      enabled: should_generate_cycles?,
      project_frequency: project_frequency,
      generation_end_date: generation_end_date,
      cycles_needed: cycles_to_generate,
      validation_errors: validate_generation_rules
    }
  end

  private

  def project_allows_generation?
    project.present? && valid_project_frequency? && project.cost.present? && project.cost > 0
  end

  def project_frequency
    project&.billing_cycle
  end

  def valid_project_frequency?
    return false unless project_frequency.present?
    config.supports_frequency?(project_frequency)
  end

  def calculate_cycle_amount(due_date)
    return 0 unless project.present?

    # Basic calculation - could be enhanced with membership logic later
    base_amount = project.cost || 0

    # Apply any date-specific adjustments (holidays, prorations, etc.)
    apply_amount_adjustments(base_amount, due_date)
  end

  def apply_amount_adjustments(base_amount, due_date)
    # Future enhancement: apply business rules for amount adjustments
    # Examples: holiday discounts, proration for mid-cycle changes, etc.

    # For now, return base amount
    base_amount
  end

  def calculate_missing_cycles(end_date, existing_cycles)
    cycles_to_generate = []
    existing_due_dates = existing_cycles.pluck(:due_date).to_set

    # Start from the latest existing cycle or current date
    start_date = existing_cycles.maximum(:due_date) || Date.current
    current_date = start_date

    # Generate cycles until we reach the end_date
    iteration_count = 0
    max_iterations = 100 # Safety limit

    while current_date <= end_date && iteration_count < max_iterations
      next_due_date = next_due_date(current_date, project_frequency)

      # Only add if this due date doesn't already exist
      unless existing_due_dates.include?(next_due_date)
        cycle_data = generate_cycle_data(next_due_date)
        cycles_to_generate << cycle_data if cycle_data
        existing_due_dates.add(next_due_date)
      end

      current_date = next_due_date
      iteration_count += 1
    end

    cycles_to_generate
  end
end
