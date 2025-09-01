class BillingCycle < ApplicationRecord
  include CurrencySupport

  belongs_to :project
  has_many :payments, dependent: :destroy

  # Validations
  validates :total_amount, :due_date, presence: true
  validates :total_amount, numericality: { greater_than: 0 }

  # Ensure due_date is in the future when created
  validate :due_date_cannot_be_in_past, on: :create

  # Basic scopes (without hardcoded business logic)
  scope :upcoming, -> { where(due_date: Date.current...) }
  scope :overdue, -> { where(due_date: ...Date.current) }
  scope :for_project, ->(project) { where(project: project) }
  scope :by_currency, ->(currency) { joins(:project).where(projects: { currency: currency }) }
  scope :with_payments, -> { joins(:payments).distinct }
  scope :without_payments, -> { left_joins(:payments).where(payments: { id: nil }) }
  scope :archived, -> { where(archived: true) }
  scope :active, -> { where(archived: false) }

  # Class methods to replace removed scopes with configurable values
  def self.due_soon(days = nil)
    threshold_days = days || BillingConfig.current.due_soon_days
    where(due_date: Date.today..threshold_days.days.from_now)
  end

  def self.archivable
    config = BillingConfig.current
    where("due_date < ? AND archived = ?", config.archiving_cutoff_date, false)
  end

  # Simple status methods
  def overdue?
    return false unless due_date
    return false if payment_status == "paid"

    Date.current > due_date
  end

  def days_until_due
    return 0 unless due_date
    (due_date - Date.current).to_i
  end

  # Payment calculation methods
  def total_paid
    payments.where(status: :confirmed).sum(:amount)
  end

  def total_pending
    payments.where(status: :pending).sum(:amount)
  end

  def amount_remaining
    [ total_amount - total_paid, 0 ].max
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
    paid = total_paid
    if paid >= total_amount
      "paid"
    elsif paid > 0
      "partial"
    else
      "unpaid"
    end
  end

  # Currency is inherited from project
  def currency
    project&.currency
  end

  # Virtual attributes derived from due_date
  def cycle_month
    due_date&.month
  end

  def cycle_year
    due_date&.year
  end

  # Member relationship methods
  def expected_payment_per_member
    return 0 if project.cost_per_member.nil? || project.cost_per_member == 0
    project.cost_per_member
  end

  def members_who_paid(status = [ :confirmed ])
    User.joins(:payments).where(payments: { billing_cycle: self, status: }).distinct
  end

  def user_successfully_paid?(user = Current.user)
    members_who_paid([ :confirmed, :pending ]).exists?(id: user)
  end

  def user_payment_pending?(user = Current.user)
    !members_who_paid([ :confirmed, :pending ]).exists?(id: user)
  end

  def members_who_havent_paid(status = [ :confirmed ])
    all_members = [ project.user ] + project.members.to_a
    paid_members = members_who_paid(status).to_a
    all_members - paid_members
  end

  # Currency formatting methods
  def format_currency(amount)
    project.format_amount(amount)
  end

  def format_total_amount
    format_currency(total_amount)
  end

  def format_total_paid
    format_currency(total_paid)
  end

  def format_amount_remaining
    format_currency(amount_remaining)
  end

  def format_expected_payment_per_member
    format_currency(expected_payment_per_member)
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

    threshold_days = days || BillingConfig.current.due_soon_days
    due_date <= threshold_days.days.from_now && due_date >= Date.current
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

  def cycle_name
    return "Invalid Date" unless cycle_year && cycle_month
    Date.new(cycle_year, cycle_month).strftime("%B %Y")
  end

  def self.for_month_year(month, year)
    # Since cycle_month and cycle_year are now virtual, we need to filter by due_date
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(due_date: start_date..end_date)
  end

  def self.overdue
    where(due_date: ...Date.today)
      .where("total_amount > (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE billing_cycle_id = billing_cycles.id and status = 'confirmed')")
  end

  def self.upcoming(days = BillingConfig.current.due_soon_days)
    where(due_date: Date.today..(Date.today+days.days))
  end

  private

  def due_date_cannot_be_in_past
    return unless due_date.present?

    if due_date < Date.current
      errors.add(:due_date, "cannot be in the past")
    end
  end
end
