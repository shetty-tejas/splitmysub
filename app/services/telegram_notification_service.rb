class TelegramNotificationService
  def initialize
    @bot_service = TelegramBotService.new
  end

  def send_payment_reminder(billing_cycle_id, reminder_schedule_id, user_id)
    billing_cycle = BillingCycle.find(billing_cycle_id)
    reminder_schedule = ReminderSchedule.find(reminder_schedule_id)
    user = User.find(user_id)

    return false unless user.telegram_linked? && user.telegram_notifications_enabled?

    # Skip if payment already confirmed
    return false if billing_cycle.fully_paid?
    return false unless billing_cycle.members_who_havent_paid.include?(user)

    message = format_payment_reminder_message(billing_cycle, reminder_schedule, user)

    success = @bot_service.send_notification(
      user: user,
      message_type: "payment_reminder",
      content: message
    )

    if success
      Rails.logger.info "Sent Telegram payment reminder to #{user.email_address} for project #{billing_cycle.project.name}"
    else
      Rails.logger.error "Failed to send Telegram payment reminder to #{user.email_address}"
    end

    success
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "TelegramNotificationService error: #{e.message}"
    false
  rescue => e
    Rails.logger.error "TelegramNotificationService error: #{e.message}"
    false
  end

  def send_billing_cycle_notification(billing_cycle_id, user_id)
    billing_cycle = BillingCycle.find(billing_cycle_id)
    user = User.find(user_id)

    return false unless user.telegram_linked? && user.telegram_notifications_enabled?

    message = format_billing_cycle_notification_message(billing_cycle, user)

    success = @bot_service.send_notification(
      user: user,
      message_type: "billing_cycle_notification",
      content: message
    )

    if success
      Rails.logger.info "Sent Telegram billing cycle notification to #{user.email_address} for project #{billing_cycle.project.name}"
    else
      Rails.logger.error "Failed to send Telegram billing cycle notification to #{user.email_address}"
    end

    success
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "TelegramNotificationService error: #{e.message}"
    false
  rescue => e
    Rails.logger.error "TelegramNotificationService error: #{e.message}"
    false
  end

  def send_payment_confirmation(billing_cycle_id, user_id)
    billing_cycle = BillingCycle.find(billing_cycle_id)
    user = User.find(user_id)

    return false unless user.telegram_linked? && user.telegram_notifications_enabled?

    message = format_payment_confirmation_message(billing_cycle, user)

    success = @bot_service.send_notification(
      user: user,
      message_type: "payment_confirmation",
      content: message
    )

    if success
      Rails.logger.info "Sent Telegram payment confirmation to #{user.email_address} for project #{billing_cycle.project.name}"
    else
      Rails.logger.error "Failed to send Telegram payment confirmation to #{user.email_address}"
    end

    success
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "TelegramNotificationService error: #{e.message}"
    false
  rescue => e
    Rails.logger.error "TelegramNotificationService error: #{e.message}"
    false
  end

  def send_account_link_verification(user_id, token)
    user = User.find(user_id)

    message = format_account_link_message(user, token)

    # This would typically be sent to a temporary chat or handled differently
    # For now, we'll just log it - in practice, this would be part of the linking flow
    Rails.logger.info "Telegram verification token generated for #{user.email_address}: #{token}"

    true
  end

  private

  def format_payment_reminder_message(billing_cycle, reminder_schedule, user)
    project = billing_cycle.project
    amount = user.format_currency(project.cost_per_member, project.currency)
    days_until_due = billing_cycle.days_until_due
    escalation_level = reminder_schedule.escalation_level

    emoji = case escalation_level
    when 1 then "🟢"
    when 2 then "🟡"
    when 3 then "🟠"
    when 4, 5 then "🔴"
    else "💰"
    end

    urgency_text = case escalation_level
    when 1 then "Friendly reminder"
    when 2 then "Reminder"
    when 3 then "URGENT"
    when 4, 5 then "FINAL NOTICE"
    else "Payment reminder"
    end

    if days_until_due > 0
      due_text = "Due in #{days_until_due} day#{'s' if days_until_due != 1}"
    elsif days_until_due == 0
      due_text = "Due today"
    else
      due_text = "#{-days_until_due} day#{'s' if days_until_due != -1} overdue"
    end

    <<~MESSAGE
      #{emoji} <b>#{urgency_text}</b>

      <b>#{project.name}</b>
      Amount: #{amount}
      #{due_text}

      #{project.description if project.description.present?}

      💡 Mark as paid: /pay #{project.name.downcase.gsub(/\s+/, '_')}
      📊 View all payments: /payments
    MESSAGE
  end

  def format_billing_cycle_notification_message(billing_cycle, user)
    project = billing_cycle.project
    amount = user.format_currency(project.cost_per_member, project.currency)
    due_date = billing_cycle.due_date.strftime("%B %d, %Y")

    <<~MESSAGE
      📅 <b>New billing cycle created</b>

      <b>#{project.name}</b>
      Amount: #{amount}
      Due date: #{due_date}

      #{project.description if project.description.present?}

      💡 Mark as paid: /pay #{project.name.downcase.gsub(/\s+/, '_')}
      📊 View status: /status
    MESSAGE
  end

  def format_payment_confirmation_message(billing_cycle, user)
    project = billing_cycle.project
    amount = user.format_currency(project.cost_per_member, project.currency)
    payment = billing_cycle.payments.where(user: user).last

    confirmation_text = if payment&.confirmation_date
      "Confirmed: #{payment.confirmation_date.strftime('%B %d, %Y')}"
    else
      "Payment confirmed!"
    end

    <<~MESSAGE
      ✅ <b>Payment confirmed!</b>

      <b>#{project.name}</b>
      Amount: #{amount}
      #{confirmation_text}

      Thank you for your payment!

      📊 View all payments: /payments
    MESSAGE
  end

  def format_account_link_message(user, token)
    <<~MESSAGE
      🔗 <b>Link your SplitMySub account</b>

      Hello #{user.first_name}!

      To start receiving notifications through Telegram, click the link below or type:

      <code>/start #{token}</code>

      This link will expire in 30 minutes.
    MESSAGE
  end
end
