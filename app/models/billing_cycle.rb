class BillingCycle < ApplicationRecord
  belongs_to :project
  has_many :payments, dependent: :destroy

  # Validations
  validates :due_date, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }

  # Ensure due_date is in the future when created
  validate :due_date_cannot_be_in_past, on: :create

  # Scopes for common queries
  scope :upcoming, -> { where("due_date >= ?", Date.current) }
  scope :overdue, -> { where("due_date < ?", Date.current) }
  scope :due_soon, ->(days = 7) { where(due_date: Date.current..days.days.from_now) }
  scope :for_project, ->(project) { where(project: project) }
  scope :with_payments, -> { joins(:payments).distinct }
  scope :without_payments, -> { left_joins(:payments).where(payments: { id: nil }) }

  # Business logic methods
  def overdue?
    due_date && due_date < Date.current
  end

  def due_soon?(days = 7)
    due_date && due_date <= days.days.from_now && due_date >= Date.current
  end

  def days_until_due
    return 0 unless due_date
    (due_date - Date.current).to_i
  end

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

  private

  def due_date_cannot_be_in_past
    if due_date && due_date < Date.current
      errors.add(:due_date, "cannot be in the past")
    end
  end
end
