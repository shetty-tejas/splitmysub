class BillingCycleGeneratorService
  def self.generate_upcoming_cycles(project, months_ahead = 3)
    new(project, months_ahead).generate_upcoming_cycles
  end

  def self.generate_all_upcoming_cycles(months_ahead = 3)
    new(nil, months_ahead).generate_all_upcoming_cycles
  end

  def initialize(project = nil, months_ahead = 3)
    @project = project
    @months_ahead = months_ahead
    @current_date = Date.current
  end

  def generate_upcoming_cycles
    return [] unless @project

    generated_cycles = []
    next_due_date = calculate_next_due_date

    # Generate cycles for the specified months ahead
    end_date = @months_ahead.months.from_now.to_date

    while next_due_date <= end_date
      # Only create cycles that are in the future
      if next_due_date > @current_date
        # Check if billing cycle already exists for this due date
        unless billing_cycle_exists?(next_due_date)
          billing_cycle = create_billing_cycle(next_due_date)
          if billing_cycle.persisted?
            generated_cycles << billing_cycle
            schedule_reminders_for_cycle(billing_cycle)
          end
        end
      end

      next_due_date = calculate_next_cycle_date(next_due_date)
    end

    generated_cycles
  end

  def generate_all_upcoming_cycles
    generated_cycles = []

    Project.active.find_each do |project|
      @project = project
      cycles = generate_upcoming_cycles
      generated_cycles.concat(cycles)
    end

    generated_cycles
  end

  private

  def calculate_next_due_date
    # Find the latest billing cycle for this project
    latest_cycle = @project.billing_cycles.order(due_date: :desc).first

    if latest_cycle
      # Calculate next cycle based on the latest cycle's due date
      calculate_next_cycle_date(latest_cycle.due_date)
    else
      # No existing cycles, use project's renewal date as base
      if @project.renewal_date >= @current_date
        @project.renewal_date
      else
        # Project renewal date is in the past, calculate next renewal
        calculate_next_renewal_date
      end
    end
  end

  def calculate_next_cycle_date(from_date)
    case @project.billing_cycle
    when "monthly"
      from_date + 1.month
    when "quarterly"
      from_date + 3.months
    when "yearly"
      from_date + 1.year
    else
      from_date + 1.month # Default to monthly
    end
  end

  def calculate_next_renewal_date
    base_date = @project.renewal_date

    case @project.billing_cycle
    when "monthly"
      while base_date < @current_date
        base_date += 1.month
      end
    when "quarterly"
      while base_date < @current_date
        base_date += 3.months
      end
    when "yearly"
      while base_date < @current_date
        base_date += 1.year
      end
    end

    base_date
  end

  def billing_cycle_exists?(due_date)
    @project.billing_cycles.exists?(due_date: due_date)
  end

  def create_billing_cycle(due_date)
    @project.billing_cycles.create(
      due_date: due_date,
      total_amount: @project.cost
    )
  end

  def schedule_reminders_for_cycle(billing_cycle)
    ReminderService.schedule_reminders_for_billing_cycle(billing_cycle)
  rescue => e
    Rails.logger.error "Failed to schedule reminders for billing cycle #{billing_cycle.id}: #{e.message}"
  end
end
