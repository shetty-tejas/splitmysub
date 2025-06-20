class BillingCycle < ApplicationRecord
  belongs_to :project
  has_many :payments, dependent: :destroy

  # Validations
  validates :due_date, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }

  # Ensure due_date is in the future when created
  validate :due_date_cannot_be_in_past, on: :create

  # Basic scopes (without hardcoded business logic)
  scope :upcoming, -> { where("due_date >= ?", Date.current) }
  scope :overdue, -> { where("due_date < ?", Date.current) }
  scope :for_project, ->(project) { where(project: project) }
  scope :with_payments, -> { joins(:payments).distinct }
  scope :without_payments, -> { left_joins(:payments).where(payments: { id: nil }) }
  scope :archived, -> { where(archived: true) }
  scope :active, -> { where(archived: false) }

  # Class methods to replace removed scopes with configurable values
  def self.due_soon(days = nil)
    config = BillingConfig.current
    threshold_days = days || config.due_soon_days
    where(due_date: Date.current..threshold_days.days.from_now)
  end

  def self.archivable
    config = BillingConfig.current
    where("due_date < ? AND archived = ?", config.archiving_cutoff_date, false)
  end

  # Simple status methods
  def overdue?
    due_date && due_date < Date.current
  end

  def days_until_due
    return 0 unless due_date
    (due_date - Date.current).to_i
  end

  # Payment calculation methods
  def total_paid
    payments.sum(:amount)
  end

  def amount_remaining
    total_amount - total_paid
  end

  def fully_paid?
    amount_remaining <= 0
  end

  def partially_paid?
    total_paid > 0 && !fully_paid?
  end

  def unpaid?
    total_paid == 0
  end

  def payment_status
    if fully_paid?
      "paid"
    elsif partially_paid?
      "partial"
    else
      "unpaid"
    end
  end

  # Member relationship methods
  def expected_payment_per_member
    project&.cost_per_member || 0
  end

  def members_who_paid
    User.joins(:payments).where(payments: { billing_cycle: self }).distinct
  end

  def members_who_havent_paid
    all_members = [ project.user ] + project.members.to_a
    paid_members = members_who_paid.to_a
    all_members - paid_members
  end

  # Adjustment methods (data manipulation, not business logic)
  def adjust_amount!(new_amount, reason = nil)
    old_amount = total_amount
    update!(
      total_amount: new_amount,
      adjustment_reason: reason,
      adjusted_at: Time.current,
      original_amount: old_amount
    )
  end

  def adjust_due_date!(new_due_date, reason = nil)
    old_due_date = due_date
    update!(
      due_date: new_due_date,
      adjustment_reason: reason,
      adjusted_at: Time.current,
      original_due_date: old_due_date
    )
  end

  def adjusted?
    adjusted_at.present?
  end

  def adjustment_summary
    return nil unless adjusted?

    summary = []
    summary << "Amount: #{original_amount} → #{total_amount}" if original_amount != total_amount
    summary << "Due Date: #{original_due_date} → #{due_date}" if original_due_date != due_date
    summary.join(", ")
  end

  # Convenience methods that delegate to services (for backward compatibility)
  def due_soon?(days = nil)
    return false unless due_date # Guard against nil due_date
    config = BillingConfig.current
    threshold_days = days || config.due_soon_days
    due_date && due_date <= threshold_days.days.from_now && due_date >= Date.current
  end

  def archivable?
    return false unless due_date && project # Guard against nil due_date or project
    policy = BillingArchivePolicy.new(BillingConfig.current, project)
    policy.should_archive_cycle?(self)
  end

  def archive!
    return false unless due_date && project # Guard against nil due_date or project
    policy = BillingArchivePolicy.new(BillingConfig.current, project)
    policy.force_archive_cycle!(self, "Manual archive")
  end

  def unarchive!
    return false unless due_date && project # Guard against nil due_date or project
    policy = BillingArchivePolicy.new(BillingConfig.current, project)
    policy.unarchive_cycle!(self, "Manual unarchive")
  end

  def archived?
    archived
  end

  private

  def due_date_cannot_be_in_past
    if due_date && due_date < Date.current
      errors.add(:due_date, "cannot be in the past")
    end
  end
end
