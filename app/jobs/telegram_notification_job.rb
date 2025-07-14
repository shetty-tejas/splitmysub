class TelegramNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_type:, **args)
    service = TelegramNotificationService.new

    case notification_type
    when "payment_reminder"
      service.send_payment_reminder(
        args[:billing_cycle_id],
        args[:reminder_schedule_id],
        args[:user_id]
      )
    when "billing_cycle_notification"
      service.send_billing_cycle_notification(
        args[:billing_cycle_id],
        args[:user_id]
      )
    when "payment_confirmation"
      service.send_payment_confirmation(
        args[:billing_cycle_id],
        args[:user_id]
      )
    when "account_link_verification"
      service.send_account_link_verification(
        args[:user_id],
        args[:token]
      )
    else
      Rails.logger.error "Unknown Telegram notification type: #{notification_type}"
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "TelegramNotificationJob failed: Record not found - #{e.message}"
  rescue => e
    Rails.logger.error "TelegramNotificationJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end
