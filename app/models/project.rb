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
  validates :billing_cycle, presence: true
  validates :renewal_date, presence: true
  validates :reminder_days, presence: true, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 30
  }

  # Dynamic validation for billing_cycle based on BillingConfig
  validate :validate_billing_cycle_frequency

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

  # Updated to use configurable frequencies
  def next_billing_cycle
    calculate_next_billing_date(renewal_date)
  end

  # New method to calculate next billing date from any date
  def calculate_next_billing_date(from_date = Date.current)
    case billing_cycle.to_s
    when "daily"
      from_date + 1.day
    when "weekly"
      from_date + 1.week
    when "monthly"
      from_date + 1.month
    when "quarterly"
      from_date + 3.months
    when "yearly"
      from_date + 1.year
    else
      # Fallback to monthly if frequency is not recognized
      from_date + 1.month
    end
  end

  # Frequency management methods
  def supported_frequencies
    BillingConfig.current.supported_billing_frequencies
  end

  def can_use_frequency?(frequency)
    supported_frequencies.include?(frequency.to_s)
  end

  def update_billing_frequency!(new_frequency)
    return false unless can_use_frequency?(new_frequency)

    update!(billing_cycle: new_frequency.to_s)
  end

  def billing_frequency_display
    billing_cycle.humanize
  end

  # Calculate billing period duration in days (for statistics and calculations)
  def billing_period_days
    case billing_cycle.to_s
    when "daily"
      1
    when "weekly"
      7
    when "monthly"
      30 # Approximate
    when "quarterly"
      90 # Approximate
    when "yearly"
      365 # Approximate
    else
      30 # Default to monthly
    end
  end

  # Calculate annual cost based on frequency
  def annual_cost
    case billing_cycle.to_s
    when "daily"
      cost * 365
    when "weekly"
      cost * 52
    when "monthly"
      cost * 12
    when "quarterly"
      cost * 4
    when "yearly"
      cost
    else
      cost * 12 # Default to monthly
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

  private

  def validate_billing_cycle_frequency
    return if billing_cycle.blank? # Let presence validation handle this

    config = BillingConfig.current
    unless config.supports_frequency?(billing_cycle)
      errors.add(:billing_cycle, "#{billing_cycle} is not a supported billing frequency. Supported frequencies: #{config.supported_billing_frequencies.join(', ')}")
    end
  rescue => e
    # If BillingConfig is not available (e.g., during tests), fall back to basic validation
    Rails.logger.warn "BillingConfig not available for validation: #{e.message}"
    unless %w[daily weekly monthly quarterly yearly].include?(billing_cycle.to_s)
      errors.add(:billing_cycle, "is not a valid billing cycle")
    end
  end
end
