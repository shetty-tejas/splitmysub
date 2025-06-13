class ReminderService
  def self.process_all_reminders
    new.process_all_reminders
  end

  def self.process_project_reminders(project)
    new.process_project_reminders(project)
  end

  def self.schedule_reminders_for_billing_cycle(billing_cycle)
    new.schedule_reminders_for_billing_cycle(billing_cycle)
  end

  def initialize
    @current_date = Date.current
  end

  def process_all_reminders
    projects_with_upcoming_billing = Project.joins(:billing_cycles)
                                           .where(billing_cycles: { due_date: @current_date..30.days.from_now })
                                           .distinct

    projects_with_upcoming_billing.find_each do |project|
      process_project_reminders(project)
    end
  end

  def process_project_reminders(project)
    upcoming_billing_cycles = project.billing_cycles.upcoming.due_soon(30)

    upcoming_billing_cycles.each do |billing_cycle|
      next if billing_cycle.fully_paid?

      schedule_reminders_for_billing_cycle(billing_cycle)
    end
  end

  def schedule_reminders_for_billing_cycle(billing_cycle)
    project = billing_cycle.project
    reminder_schedules = project.reminder_schedules.ordered_by_days

    reminder_schedules.each do |reminder_schedule|
      next unless should_send_reminder?(billing_cycle, reminder_schedule)

      members_to_remind = get_members_to_remind(billing_cycle)

      members_to_remind.each do |member|
        schedule_reminder_for_member(billing_cycle, reminder_schedule, member)
      end
    end
  end

  private

  def should_send_reminder?(billing_cycle, reminder_schedule)
    reminder_date = reminder_schedule.reminder_date_for(billing_cycle)

    # Send reminder if today is the reminder date or later, but before due date
    @current_date >= reminder_date && @current_date < billing_cycle.due_date
  end

  def get_members_to_remind(billing_cycle)
    # Get all members who haven't paid yet
    unpaid_members = billing_cycle.members_who_havent_paid

    # Filter out users who have unsubscribed from this project
    unpaid_members.reject do |member|
      preferences = member.preferences
      if preferences.is_a?(String)
        # Handle case where preferences is stored as JSON string
        begin
          preferences = JSON.parse(preferences)
        rescue JSON::ParserError
          preferences = {}
        end
      end
      preferences&.dig("unsubscribed_projects")&.include?(billing_cycle.project.id)
    end
  end

  def schedule_reminder_for_member(billing_cycle, reminder_schedule, member)
    # Check if we've already sent this reminder level to this member today
    return if reminder_already_sent_today?(billing_cycle, reminder_schedule, member)

    # Schedule the reminder email job
    ReminderMailerJob.perform_later(
      billing_cycle_id: billing_cycle.id,
      reminder_schedule_id: reminder_schedule.id,
      user_id: member.id
    )

    # Log the reminder
    Rails.logger.info "Scheduled #{reminder_schedule.escalation_description} reminder for #{member.email_address} for project #{billing_cycle.project.name}"
  end

  def reminder_already_sent_today?(billing_cycle, reminder_schedule, member)
    # This would require a ReminderLog model to track sent reminders
    # For now, we'll implement a simple check based on job queue
    # In a production system, you'd want to track this in the database
    false
  end
end
