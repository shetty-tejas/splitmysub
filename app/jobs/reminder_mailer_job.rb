class ReminderMailerJob < ApplicationJob
  queue_as :default

  # retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(billing_cycle_id:, reminder_schedule_id:, user_id:)
    billing_cycle = BillingCycle.find(billing_cycle_id)
    reminder_schedule = ReminderSchedule.find(reminder_schedule_id)
    user = User.find(user_id)

    # Double-check that the user still needs a reminder
    return if billing_cycle.fully_paid?
    return unless billing_cycle.members_who_havent_paid.include?(user)

    # Send the reminder email
    ReminderMailer.payment_reminder(
      billing_cycle_id,
      reminder_schedule_id,
      user_id
    ).deliver_now

    # Send Telegram notification if user has it enabled
    TelegramNotificationJob.perform_later(
      notification_type: "payment_reminder",
      billing_cycle_id: billing_cycle_id,
      reminder_schedule_id: reminder_schedule_id,
      user_id: user_id
    )

    # Log the successful delivery
    Rails.logger.info "Sent #{reminder_schedule.escalation_description} reminder to #{user.email_address} for project #{billing_cycle.project.name}"

    # Create a reminder log entry (if we had a ReminderLog model)
    # ReminderLog.create!(
    #   billing_cycle: billing_cycle,
    #   reminder_schedule: reminder_schedule,
    #   user: user,
    #   sent_at: Time.current,
    #   email_subject: ReminderMailer.new.send(:email_subject)
    # )

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "ReminderMailerJob failed: Record not found - #{e.message}"
    # Don't retry if records are missing
    raise e
  rescue StandardError => e
    Rails.logger.error "ReminderMailerJob failed: #{e.message}"
    raise e
  end
end
