class BillingConfig < ApplicationRecord
  # Singleton pattern - only one configuration should exist
  before_create :ensure_single_instance
  validate :validate_single_instance_on_update, on: :update

  # Validations
  validates :generation_months_ahead, presence: true, numericality: {
    greater_than: 0, less_than_or_equal_to: 12
  }
  validates :archiving_months_threshold, presence: true, numericality: {
    greater_than: 0, less_than_or_equal_to: 24
  }
  validates :due_soon_days, presence: true, numericality: {
    greater_than: 0, less_than_or_equal_to: 30
  }
  validates :payment_grace_period_days, presence: true, numericality: {
    greater_than_or_equal_to: 0, less_than_or_equal_to: 30
  }
  validates :default_billing_frequencies, presence: true
  validates :supported_billing_frequencies, presence: true
  validates :reminder_schedule, presence: true

  # Reminder field validations
  validates :gentle_reminder_days_before, presence: true, numericality: {
    greater_than: 0, less_than_or_equal_to: 30
  }
  validates :standard_reminder_days_overdue, presence: true, numericality: {
    greater_than_or_equal_to: 0, less_than_or_equal_to: 30
  }
  validates :urgent_reminder_days_overdue, presence: true, numericality: {
    greater_than_or_equal_to: 0, less_than_or_equal_to: 60
  }
  validates :final_notice_days_overdue, presence: true, numericality: {
    greater_than_or_equal_to: 0, less_than_or_equal_to: 90
  }
  validates :default_frequency, presence: true, inclusion: {
    in: %w[daily weekly monthly quarterly yearly]
  }

  # JSON serialization for array fields - handle both arrays and JSON strings
  def default_billing_frequencies
    parse_json_array(super)
  end

  def supported_billing_frequencies
    parse_json_array(super)
  end

  def reminder_schedule
    parse_json_array(super)
  end

  # Custom validations
  validate :validate_frequency_arrays
  validate :validate_reminder_schedule_format
  validate :validate_default_frequencies_subset

  # Class methods for singleton access
  def self.current
    first || create_default!
  end

  def self.create_default!
    create!(
      generation_months_ahead: 3,
      archiving_months_threshold: 6,
      due_soon_days: 30,
      auto_archiving_enabled: true,
      auto_generation_enabled: true,
      default_billing_frequencies: [ "monthly" ],
      supported_billing_frequencies: [ "monthly", "quarterly", "yearly" ],
      reminder_schedule: [ 7, 3, 1 ],
      payment_grace_period_days: 5,
      reminders_enabled: true,
      gentle_reminder_days_before: 3,
      standard_reminder_days_overdue: 1,
      urgent_reminder_days_overdue: 7,
      final_notice_days_overdue: 14,
      default_frequency: "monthly"
    )
  end

  # Instance methods for easy access to configuration values
  def generation_end_date
    generation_months_ahead.months.from_now.to_date
  end

  def archiving_cutoff_date
    archiving_months_threshold.months.ago.to_date
  end

  def is_due_soon?(due_date)
    due_date <= due_soon_days.days.from_now.to_date && due_date >= Date.current
  end

  def is_archivable?(billing_cycle)
    billing_cycle.due_date < archiving_cutoff_date &&
    !billing_cycle.archived? &&
    auto_archiving_enabled?
  end

  def reminder_days_before
    reminder_schedule.sort.reverse
  end

  def supports_frequency?(frequency)
    supported_billing_frequencies.include?(frequency.to_s)
  end



  # Configuration update methods
  def update_generation_settings!(months_ahead:, auto_enabled: nil)
    update!(
      generation_months_ahead: months_ahead,
      auto_generation_enabled: auto_enabled.nil? ? auto_generation_enabled : auto_enabled
    )
  end

  def update_archiving_settings!(months_threshold:, auto_enabled: nil)
    update!(
      archiving_months_threshold: months_threshold,
      auto_archiving_enabled: auto_enabled.nil? ? auto_archiving_enabled : auto_enabled
    )
  end

  def update_reminder_settings!(schedule:, grace_period: nil)
    update!(
      reminder_schedule: schedule,
      payment_grace_period_days: grace_period || payment_grace_period_days
    )
  end

  def add_supported_frequency!(frequency)
    return if supports_frequency?(frequency)

    update!(supported_billing_frequencies: supported_billing_frequencies + [ frequency.to_s ])
  end

  def remove_supported_frequency!(frequency)
    return unless supports_frequency?(frequency)
    return if default_billing_frequencies.include?(frequency.to_s)

    new_frequencies = supported_billing_frequencies - [ frequency.to_s ]
    update!(supported_billing_frequencies: new_frequencies)
  end

  # Export configuration for debugging/backup
  def to_configuration_hash
    {
      generation: {
        months_ahead: generation_months_ahead,
        auto_enabled: auto_generation_enabled
      },
      archiving: {
        months_threshold: archiving_months_threshold,
        auto_enabled: auto_archiving_enabled
      },
      due_soon_days: due_soon_days,
      frequencies: {
        supported: supported_billing_frequencies,
        default: default_billing_frequencies
      },
      reminders: {
        schedule: reminder_schedule,
        grace_period_days: payment_grace_period_days
      }
    }
  end

  private

  def ensure_single_instance
    if BillingConfig.exists?
      errors.add(:base, "Only one billing configuration can exist")
      throw :abort
    end
  end

  def validate_single_instance_on_update
    if BillingConfig.where.not(id: id).exists?
      errors.add(:base, "Only one billing configuration can exist")
    end
  end

  def validate_frequency_arrays
    # Parse JSON if needed
    default_freqs = parse_json_array(default_billing_frequencies)
    supported_freqs = parse_json_array(supported_billing_frequencies)

    if default_freqs.blank?
      errors.add(:default_billing_frequencies, "must be a non-empty array")
    end

    if supported_freqs.blank?
      errors.add(:supported_billing_frequencies, "must be a non-empty array")
    end

    return if default_freqs.blank? || supported_freqs.blank?

    # Validate frequency values - now includes daily
    valid_frequencies = %w[daily weekly monthly quarterly yearly]
    invalid_supported = supported_freqs - valid_frequencies
    if invalid_supported.any?
      errors.add(:supported_billing_frequencies, "contains invalid frequencies: #{invalid_supported.join(', ')}")
    end

    invalid_default = default_freqs - valid_frequencies
    if invalid_default.any?
      errors.add(:default_billing_frequencies, "contains invalid frequencies: #{invalid_default.join(', ')}")
    end
  end

    def validate_reminder_schedule_format
    schedule = parse_json_array(reminder_schedule)

    if schedule.blank?
      errors.add(:reminder_schedule, "must be a non-empty array")
      return
    end

    unless schedule.all? { |day| day.is_a?(Integer) && day > 0 }
      errors.add(:reminder_schedule, "must contain only positive integers")
    end
  end

  def validate_default_frequencies_subset
    default_freqs = parse_json_array(default_billing_frequencies)
    supported_freqs = parse_json_array(supported_billing_frequencies)

    return if default_freqs.blank? || supported_freqs.blank?

    invalid_defaults = default_freqs - supported_freqs
    if invalid_defaults.any?
      errors.add(:default_billing_frequencies, "must be a subset of supported frequencies")
    end
  end

  # Helper method to parse JSON arrays
  def parse_json_array(value)
    return [] if value.blank?
    return value if value.is_a?(Array)

    begin
      parsed = JSON.parse(value)
      parsed.is_a?(Array) ? parsed : []
    rescue JSON::ParserError
      []
    end
  end
end
