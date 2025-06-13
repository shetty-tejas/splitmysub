class CleanupOldPaymentEvidenceJob < ApplicationJob
  queue_as :default

  def perform
    # Find payments older than 1 year with evidence attached
    old_payments = Payment.joins(:evidence_attachment)
                          .where("payments.created_at < ?", 1.year.ago)
                          .includes(:evidence_attachment)

    cleanup_count = 0

    old_payments.find_each do |payment|
      if payment.evidence.attached?
        Rails.logger.info "Cleaning up evidence for payment #{payment.id} (created #{payment.created_at})"
        payment.evidence.purge
        cleanup_count += 1
      end
    end

    Rails.logger.info "Cleaned up #{cleanup_count} old payment evidence files"
    cleanup_count
  end
end
