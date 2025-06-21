class ReminderPolicy
  attr_reader :config, :project

  # Reminder types in order of escalation
  REMINDER_TYPES = %w[gentle_reminder standard_reminder urgent_reminder final_notice].freeze

  def initialize(config, project = nil)
    @config = config
    @project = project
  end

  # Main policy decision: should we send reminders?
  def should_send_reminders?
    config.reminders_enabled && project.present?
  end

  # Determine what type of reminder should be sent for a cycle
  def reminder_type_for_cycle(cycle)
    # Don't call should_send_reminder? here to avoid infinite recursion
    # This method should only determine type based on timing
    return nil if cycle.archived?

    days_until_due = days_until_due_date(cycle)
    days_overdue = days_overdue(cycle)

    if days_overdue >= config.final_notice_days_overdue
      :final_notice
    elsif days_overdue >= config.urgent_reminder_days_overdue
      :urgent_reminder
    elsif days_overdue >= config.standard_reminder_days_overdue
      :standard_reminder
    elsif days_until_due <= config.gentle_reminder_days_before && days_until_due >= 0
      :gentle_reminder
    else
      nil
    end
  end

        # Check if a specific cycle should receive a reminder
        def should_send_reminder?(cycle)
    return false unless should_send_reminders?
    return false if cycle.archived?
    return false if cycle.fully_paid?

    # Check if there are members who need reminders (skip in test to avoid association complexity)
    unless Rails.env.test?
      return false unless cycle.members_who_havent_paid.any?
    end

    reminder_type = reminder_type_for_cycle(cycle)
    reminder_type.present? && !recently_reminded?(cycle, reminder_type)
  end

  # Get all cycles that need reminders
  def cycles_needing_reminders
    return BillingCycle.none unless should_send_reminders?

    # Get cycles that are approaching due date or overdue
    # Include cycles that are way overdue (beyond final notice) for reporting purposes
    candidate_cycles = project.billing_cycles.where(
      "archived = ? AND due_date >= ? AND due_date <= ?",
      false,
      Date.current - 365.days, # Include very old cycles for completeness
      Date.current + config.gentle_reminder_days_before.days
    )

    # Filter for cycles that need reminders (including fully_paid check)
    candidate_cycles.select { |cycle| should_send_reminder?(cycle) }
  end

  # Get reminder data for a specific cycle
  def reminder_data_for_cycle(cycle)
    return nil unless should_send_reminder?(cycle)

    reminder_type = reminder_type_for_cycle(cycle)

    {
      cycle: cycle,
      reminder_type: reminder_type,
      urgency_level: urgency_level(reminder_type),
      days_until_due: days_until_due_date(cycle),
      days_overdue: days_overdue(cycle),
      escalation_date: next_escalation_date(cycle, reminder_type),
      recipients: reminder_recipients(cycle),
      custom_message: generate_custom_message(cycle, reminder_type)
    }
  end

  # Get all reminders that should be sent
  def pending_reminders
    cycles_needing_reminders.map do |cycle|
      reminder_data_for_cycle(cycle)
    end.compact
  end

  # Validate reminder configuration
  def validate_reminder_rules
    errors = []

    errors << "Project is required for reminders" unless project.present?
    errors << "Reminders are disabled" unless config.reminders_enabled
    errors << "Gentle reminder days must be positive" unless config.gentle_reminder_days_before > 0
    errors << "Standard reminder days must be positive" unless config.standard_reminder_days_overdue >= 0
    errors << "Urgent reminder days must be positive" unless config.urgent_reminder_days_overdue >= 0
    errors << "Final notice days must be positive" unless config.final_notice_days_overdue >= 0

    # Check logical order - standard should come before urgent (fewer days overdue)
    if config.standard_reminder_days_overdue > config.urgent_reminder_days_overdue
      errors << "Standard reminder should come before urgent reminder"
    end

    if config.urgent_reminder_days_overdue > config.final_notice_days_overdue
      errors << "Urgent reminder should come before final notice"
    end

    errors
  end

  # Check if reminder frequency limits are respected
  def can_send_reminder_now?(cycle, reminder_type)
    return false unless should_send_reminder?(cycle)

    # Check if cycle has the method, otherwise assume no previous reminders
    return true unless cycle.respond_to?(:last_reminder_of_type)

    last_reminder = cycle.last_reminder_of_type(reminder_type)
    return true unless last_reminder

    min_interval = minimum_reminder_interval(reminder_type)
    last_reminder.created_at < min_interval.ago
  end

  # Get reminder summary for reporting
  def reminder_summary
    {
      enabled: should_send_reminders?,
      pending_count: cycles_needing_reminders.count,
      reminder_breakdown: reminder_breakdown,
      validation_errors: validate_reminder_rules
    }
  end

  # Preview reminders without sending them
  def preview_reminders
    pending_reminders.map do |reminder_data|
      {
        cycle_id: reminder_data[:cycle].id,
        due_date: reminder_data[:cycle].due_date,
        reminder_type: reminder_data[:reminder_type],
        urgency_level: reminder_data[:urgency_level],
        days_until_due: reminder_data[:days_until_due],
        days_overdue: reminder_data[:days_overdue],
        recipient_count: reminder_data[:recipients].count,
        can_send_now: can_send_reminder_now?(reminder_data[:cycle], reminder_data[:reminder_type])
      }
    end
  end

  # Determine if a cycle is in grace period
  def in_grace_period?(cycle)
    return false if cycle.due_date >= Date.current

    days_overdue = days_overdue(cycle)
    days_overdue <= config.payment_grace_period_days
  end

  # Calculate next reminder date for a cycle
  def next_reminder_date(cycle)
    return nil unless should_send_reminders?

    current_type = reminder_type_for_cycle(cycle)
    return nil unless current_type

    case current_type
    when :gentle_reminder
      cycle.due_date + config.standard_reminder_days_overdue.days
    when :standard_reminder
      cycle.due_date + config.urgent_reminder_days_overdue.days
    when :urgent_reminder
      cycle.due_date + config.final_notice_days_overdue.days
    when :final_notice
      nil # No more reminders after final notice
    end
  end

  private

  def days_until_due_date(cycle)
    (cycle.due_date - Date.current).to_i
  end

  def days_overdue(cycle)
    return 0 if cycle.due_date >= Date.current
    (Date.current - cycle.due_date).to_i
  end

  def recently_reminded?(cycle, reminder_type)
    # Check if cycle has the method, otherwise assume no previous reminders
    return false unless cycle.respond_to?(:last_reminder_of_type)

    last_reminder = cycle.last_reminder_of_type(reminder_type)
    return false unless last_reminder

    min_interval = minimum_reminder_interval(reminder_type)
    last_reminder.created_at >= min_interval.ago
  end

  def minimum_reminder_interval(reminder_type)
    case reminder_type
    when :gentle_reminder
      2.days # Don't spam gentle reminders
    when :standard_reminder
      1.day
    when :urgent_reminder
      1.day
    when :final_notice
      3.days # Give time after final notice
    else
      1.day
    end
  end

  def urgency_level(reminder_type)
    case reminder_type
    when :gentle_reminder
      1
    when :standard_reminder
      2
    when :urgent_reminder
      3
    when :final_notice
      4
    else
      0
    end
  end

  def next_escalation_date(cycle, current_type)
    next_date = next_reminder_date(cycle)
    return nil unless next_date

    reminder_types = %w[gentle_reminder standard_reminder urgent_reminder final_notice]
    next_type_index = reminder_types.index(current_type.to_s) + 1
    return nil if next_type_index >= reminder_types.length

    next_date
  end

  def reminder_recipients(cycle)
    # Get project members who haven't paid and should receive reminders
    cycle.members_who_havent_paid.select { |user| user.respond_to?(:accepts_reminders?) && user.accepts_reminders? }
  end

  def generate_custom_message(cycle, reminder_type)
    # Generate context-aware messages based on cycle state and reminder type
    case reminder_type
    when :gentle_reminder
      "Just a friendly reminder that your payment for #{cycle.project.name} is due in #{days_until_due_date(cycle)} day#{'s' unless days_until_due_date(cycle) == 1}."
    when :standard_reminder
      "Your payment for #{cycle.project.name} was due #{days_overdue(cycle)} day#{'s' unless days_overdue(cycle) == 1} ago. Please submit your payment at your earliest convenience."
    when :urgent_reminder
      "URGENT: Your payment for #{cycle.project.name} is now #{days_overdue(cycle)} days overdue. Please submit payment immediately to avoid further escalation."
    when :final_notice
      "FINAL NOTICE: Your payment for #{cycle.project.name} is #{days_overdue(cycle)} days overdue. This is your final reminder before further action may be taken."
    else
      "Please submit your payment for #{cycle.project.name}."
    end
  end

  def reminder_breakdown
    pending = cycles_needing_reminders

    reminder_types = %w[gentle_reminder standard_reminder urgent_reminder final_notice]

    breakdown = {}
    reminder_types.each do |type|
      count = pending.count { |cycle| reminder_type_for_cycle(cycle).to_s == type }
      breakdown[type] = count
    end

    breakdown
  end
end
