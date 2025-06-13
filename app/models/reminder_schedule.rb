class ReminderSchedule < ApplicationRecord
  belongs_to :project

  # Validations
  validates :days_before, presence: true, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 30
  }
  validates :escalation_level, presence: true, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 5
  }
  validates :days_before, uniqueness: {
    scope: :project_id,
    message: "already has a reminder scheduled for this number of days for this project"
  }

  # Scopes for common queries
  scope :for_project, ->(project) { where(project: project) }
  scope :by_escalation_level, ->(level) { where(escalation_level: level) }
  scope :early_reminders, -> { where("days_before >= ?", 7) }
  scope :urgent_reminders, -> { where("days_before <= ?", 3) }
  scope :ordered_by_days, -> { order(:days_before) }
  scope :ordered_by_escalation, -> { order(:escalation_level) }

  # Business logic methods
  def early_reminder?
    days_before >= 7
  end

  def urgent_reminder?
    days_before <= 3
  end

  def reminder_date_for(billing_cycle)
    billing_cycle.due_date - days_before.days
  end

  def should_send_reminder?(billing_cycle)
    reminder_date = reminder_date_for(billing_cycle)
    Date.current >= reminder_date && Date.current < billing_cycle.due_date
  end

  def escalation_description
    case escalation_level
    when 1
      "Gentle reminder"
    when 2
      "Standard reminder"
    when 3
      "Urgent reminder"
    when 4
      "Final notice"
    when 5
      "Critical alert"
    else
      "Reminder"
    end
  end

  def reminder_urgency
    case escalation_level
    when 1..2
      "low"
    when 3
      "medium"
    when 4..5
      "high"
    else
      "medium"
    end
  end
end
