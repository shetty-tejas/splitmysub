class Project < ApplicationRecord
  belongs_to :user
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user
  has_many :billing_cycles, dependent: :destroy
  has_many :reminder_schedules, dependent: :destroy
  has_many :payments, through: :billing_cycles
  has_many :invitations, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :cost, presence: true, numericality: { greater_than: 0 }
  validates :billing_cycle, presence: true, inclusion: {
    in: %w[monthly quarterly yearly],
    message: "%{value} is not a valid billing cycle"
  }
  validates :renewal_date, presence: true
  validates :reminder_days, presence: true, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 30
  }

  # Scopes for common queries
  scope :active, -> { where("renewal_date >= ?", Date.current) }
  scope :expiring_soon, ->(days = 7) { where(renewal_date: Date.current..days.days.from_now) }
  scope :by_billing_cycle, ->(cycle) { where(billing_cycle: cycle) }
  scope :with_members, -> { joins(:project_memberships).distinct }

  # Business logic methods
  def active?
    renewal_date >= Date.current
  end

  def expired?
    !active?
  end

  def days_until_renewal
    (renewal_date - Date.current).to_i
  end

  def expiring_soon?(days = 7)
    days_until_renewal <= days && days_until_renewal >= 0
  end

  def total_members
    project_memberships.count + 1 # +1 for owner
  end

  def cost_per_member
    cost / total_members
  end

  def next_billing_cycle
    case billing_cycle
    when "monthly"
      renewal_date + 1.month
    when "quarterly"
      renewal_date + 3.months
    when "yearly"
      renewal_date + 1.year
    end
  end

  def owner
    user
  end

  def is_owner?(user)
    self.user == user
  end

  def is_member?(user)
    project_memberships.exists?(user: user)
  end

  def has_access?(user)
    is_owner?(user) || is_member?(user)
  end
end
