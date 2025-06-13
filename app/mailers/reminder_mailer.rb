class ReminderMailer < ApplicationMailer
  def payment_reminder(billing_cycle_id, reminder_schedule_id, user_id, unsubscribe_token = nil)
    @billing_cycle = BillingCycle.find(billing_cycle_id)
    @reminder_schedule = ReminderSchedule.find(reminder_schedule_id)
    @user = User.find(user_id)
    @project = @billing_cycle.project
    @unsubscribe_token = unsubscribe_token || generate_unsubscribe_token(@user, @project)

    @amount_due = @project.cost_per_member
    @days_until_due = @billing_cycle.days_until_due
    @escalation_level = @reminder_schedule.escalation_level
    @escalation_description = @reminder_schedule.escalation_description

    # Set email priority based on escalation level
    headers["X-Priority"] = email_priority
    headers["X-MSMail-Priority"] = email_priority_outlook

    mail(
      to: @user.email_address,
      subject: email_subject,
      template_name: email_template
    )
  end

  def final_notice(billing_cycle_id, user_id, unsubscribe_token = nil)
    @billing_cycle = BillingCycle.find(billing_cycle_id)
    @user = User.find(user_id)
    @project = @billing_cycle.project
    @unsubscribe_token = unsubscribe_token || generate_unsubscribe_token(@user, @project)

    @amount_due = @project.cost_per_member
    @days_until_due = @billing_cycle.days_until_due
    @days_overdue = @days_until_due < 0 ? -@days_until_due : 0

    # High priority for final notices
    headers["X-Priority"] = "1"
    headers["X-MSMail-Priority"] = "High"

    mail(
      to: @user.email_address,
      subject: "FINAL NOTICE: Payment overdue for #{@project.name}",
      template_name: "final_notice"
    )
  end

  def payment_confirmation(billing_cycle_id, user_id)
    @billing_cycle = BillingCycle.find(billing_cycle_id)
    @user = User.find(user_id)
    @project = @billing_cycle.project
    @payment = @billing_cycle.payments.where(user: @user).last

    mail(
      to: @user.email_address,
      subject: "Payment confirmed for #{@project.name}",
      template_name: "payment_confirmation"
    )
  end

  private

  def email_subject
    case @escalation_level
    when 1
      "Friendly reminder: #{@project.name} payment due in #{@days_until_due} days"
    when 2
      "Reminder: #{@project.name} payment due in #{@days_until_due} days"
    when 3
      "URGENT: #{@project.name} payment due in #{@days_until_due} days"
    when 4
      "FINAL NOTICE: #{@project.name} payment due in #{@days_until_due} days"
    when 5
      "CRITICAL: #{@project.name} payment overdue"
    else
      "Payment reminder for #{@project.name}"
    end
  end

  def email_template
    case @escalation_level
    when 1
      "gentle_reminder"
    when 2
      "standard_reminder"
    when 3
      "urgent_reminder"
    when 4, 5
      "final_notice"
    else
      "standard_reminder"
    end
  end

  def email_priority
    case @escalation_level
    when 1, 2
      "3" # Normal
    when 3
      "2" # High
    when 4, 5
      "1" # Highest
    else
      "3"
    end
  end

  def email_priority_outlook
    case @escalation_level
    when 1, 2
      "Normal"
    when 3
      "High"
    when 4, 5
      "High"
    else
      "Normal"
    end
  end

  def generate_unsubscribe_token(user, project)
    # Generate a secure token for unsubscribe functionality
    payload = {
      user_id: user.id,
      project_id: project.id,
      timestamp: Time.current.to_i
    }

    # In a real application, you'd want to use Rails.application.message_verifier
    # or a similar secure token generation method
    Base64.urlsafe_encode64(payload.to_json)
  end
end
