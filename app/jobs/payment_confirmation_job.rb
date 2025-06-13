class PaymentConfirmationJob < ApplicationJob
  queue_as :default

  # retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(payment_id)
    payment = Payment.find(payment_id)

    # Only send confirmation if payment is confirmed
    return unless payment.confirmed?

    # Send the confirmation email
    ReminderMailer.payment_confirmation(
      payment.billing_cycle.id,
      payment.user.id
    ).deliver_now

    # Log the successful delivery
    Rails.logger.info "Sent payment confirmation email to #{payment.user.email_address} for project #{payment.billing_cycle.project.name}"

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "PaymentConfirmationJob failed: Payment not found - #{e.message}"
    # Don't retry if payment is missing
    raise e
  rescue StandardError => e
    Rails.logger.error "PaymentConfirmationJob failed: #{e.message}"
    raise e
  end
end
