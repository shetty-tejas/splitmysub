require "test_helper"
require "ostruct"

class BillingConfigTest < ActiveSupport::TestCase
  def setup
    # Clear any existing config
    BillingConfig.delete_all
  end

  def teardown
    # Clean up after each test
    BillingConfig.delete_all
  end

  # Test singleton pattern
  test "should enforce singleton pattern" do
    config1 = BillingConfig.create!(
      generation_months_ahead: 3,
      archiving_months_threshold: 6,
      due_soon_days: 7,
      auto_archiving_enabled: true,
      auto_generation_enabled: true,
      default_billing_frequencies: [ "monthly" ],
      supported_billing_frequencies: [ "monthly", "quarterly" ],
      reminder_schedule: [ 7, 3, 1 ],
      payment_grace_period_days: 5
    )

    config2 = BillingConfig.new(
      generation_months_ahead: 4,
      archiving_months_threshold: 8,
      due_soon_days: 10,
      auto_archiving_enabled: false,
      auto_generation_enabled: false,
      default_billing_frequencies: [ "quarterly" ],
      supported_billing_frequencies: [ "monthly", "quarterly" ],
      reminder_schedule: [ 5, 2 ],
      payment_grace_period_days: 3
    )

    assert_not config2.save
    assert_includes config2.errors[:base], "Only one billing configuration can exist"
  end

  test "should get current configuration or create default" do
    assert_equal 0, BillingConfig.count

    config = BillingConfig.current

    assert_not_nil config
    assert config.persisted?
    assert_equal 1, BillingConfig.count
    assert_equal 3, config.generation_months_ahead
    assert_equal [ "monthly" ], config.default_billing_frequencies
  end

        test "should validate required fields" do
    # Test without default values by explicitly setting to nil/blank
    config = BillingConfig.new(
      generation_months_ahead: nil,
      archiving_months_threshold: nil,
      due_soon_days: nil,
      payment_grace_period_days: nil,
      default_billing_frequencies: nil,
      supported_billing_frequencies: nil,
      reminder_schedule: nil
    )

    assert_not config.valid?

    # Numeric fields should be required
    assert config.errors[:generation_months_ahead].any?
    assert config.errors[:archiving_months_threshold].any?
    assert config.errors[:due_soon_days].any?
    assert config.errors[:payment_grace_period_days].any?

    # Array fields should be required
    assert config.errors[:default_billing_frequencies].any?
    assert config.errors[:supported_billing_frequencies].any?
    assert config.errors[:reminder_schedule].any?
  end

  test "should validate numeric ranges" do
    config = BillingConfig.new(
      generation_months_ahead: 0,
      archiving_months_threshold: 25,
      due_soon_days: 31,
      payment_grace_period_days: -1,
      default_billing_frequencies: [ "monthly" ],
      supported_billing_frequencies: [ "monthly" ],
      reminder_schedule: [ 7 ]
    )

    assert_not config.valid?
    assert_includes config.errors[:generation_months_ahead], "must be greater than 0"
    assert_includes config.errors[:archiving_months_threshold], "must be less than or equal to 24"
    assert_includes config.errors[:due_soon_days], "must be less than or equal to 30"
    assert_includes config.errors[:payment_grace_period_days], "must be greater than or equal to 0"
  end

  test "should validate frequency arrays" do
    config = BillingConfig.new(
      generation_months_ahead: 3,
      archiving_months_threshold: 6,
      due_soon_days: 7,
      payment_grace_period_days: 5,
      default_billing_frequencies: [ "invalid" ],
      supported_billing_frequencies: [ "monthly", "invalid" ],
      reminder_schedule: [ 7 ]
    )

    assert_not config.valid?
    assert_includes config.errors[:supported_billing_frequencies], "contains invalid frequencies: invalid"
    assert_includes config.errors[:default_billing_frequencies], "contains invalid frequencies: invalid"
  end

  test "should validate default frequencies are subset of supported" do
    config = BillingConfig.new(
      generation_months_ahead: 3,
      archiving_months_threshold: 6,
      due_soon_days: 7,
      payment_grace_period_days: 5,
      default_billing_frequencies: [ "monthly", "yearly" ],
      supported_billing_frequencies: [ "monthly", "quarterly" ],
      reminder_schedule: [ 7 ]
    )

    assert_not config.valid?
    assert_includes config.errors[:default_billing_frequencies], "must be a subset of supported frequencies"
  end

  test "should validate reminder schedule format" do
    config = BillingConfig.new(
      generation_months_ahead: 3,
      archiving_months_threshold: 6,
      due_soon_days: 7,
      payment_grace_period_days: 5,
      default_billing_frequencies: [ "monthly" ],
      supported_billing_frequencies: [ "monthly" ],
      reminder_schedule: [ 7, -1, 0 ]
    )

    assert_not config.valid?
    assert_includes config.errors[:reminder_schedule], "must contain only positive integers"
  end

  # Test instance methods
  test "generation_end_date should return correct date" do
    config = create_valid_config

    expected_date = 3.months.from_now.to_date
    assert_equal expected_date, config.generation_end_date
  end

  test "archiving_cutoff_date should return correct date" do
    config = create_valid_config

    expected_date = 6.months.ago.to_date
    assert_equal expected_date, config.archiving_cutoff_date
  end

  test "is_due_soon should work correctly" do
    config = create_valid_config

    # Due today - should be due soon
    assert config.is_due_soon?(Date.current)

    # Due in 5 days - should be due soon (within 7 days)
    assert config.is_due_soon?(5.days.from_now.to_date)

    # Due in 8 days - should not be due soon
    assert_not config.is_due_soon?(8.days.from_now.to_date)

    # Due yesterday - should not be due soon (in the past)
    assert_not config.is_due_soon?(1.day.ago.to_date)
  end

  test "supports_frequency should work correctly" do
    config = create_valid_config

    assert config.supports_frequency?("monthly")
    assert config.supports_frequency?("quarterly")
    assert config.supports_frequency?("yearly")
    assert_not config.supports_frequency?("weekly")
  end

  test "default_frequency should return first default" do
    config = create_valid_config

    assert_equal "monthly", config.default_frequency
  end

  test "reminder_days_before should return sorted descending" do
    config = create_valid_config(reminder_schedule: [ 1, 7, 3 ])

    assert_equal [ 7, 3, 1 ], config.reminder_days_before
  end

  test "should create archivable billing cycle check" do
    config = create_valid_config

    # Create mock billing cycle
    old_cycle = OpenStruct.new(
      due_date: 7.months.ago.to_date,
      archived?: false
    )

    new_cycle = OpenStruct.new(
      due_date: 1.month.ago.to_date,
      archived?: false
    )

    archived_cycle = OpenStruct.new(
      due_date: 7.months.ago.to_date,
      archived?: true
    )

    assert config.is_archivable?(old_cycle)
    assert_not config.is_archivable?(new_cycle)
    assert_not config.is_archivable?(archived_cycle)
  end

  # Test configuration update methods
  test "should update generation settings" do
    config = create_valid_config

    config.update_generation_settings!(months_ahead: 4, auto_enabled: false)
    config.reload

    assert_equal 4, config.generation_months_ahead
    assert_equal false, config.auto_generation_enabled
  end

  test "should update archiving settings" do
    config = create_valid_config

    config.update_archiving_settings!(months_threshold: 8, auto_enabled: false)
    config.reload

    assert_equal 8, config.archiving_months_threshold
    assert_equal false, config.auto_archiving_enabled
  end

  test "should update reminder settings" do
    config = create_valid_config

    config.update_reminder_settings!(schedule: [ 10, 5, 1 ], grace_period: 7)
    config.reload

    assert_equal [ 10, 5, 1 ], config.reminder_schedule
    assert_equal 7, config.payment_grace_period_days
  end

  test "should add supported frequency" do
    config = create_valid_config

    assert_not config.supports_frequency?("weekly")

    config.add_supported_frequency!("weekly")
    config.reload

    assert config.supports_frequency?("weekly")
    assert_includes config.supported_billing_frequencies, "weekly"
  end

  test "should not add duplicate supported frequency" do
    config = create_valid_config
    original_count = config.supported_billing_frequencies.length

    config.add_supported_frequency!("monthly")
    config.reload

    assert_equal original_count, config.supported_billing_frequencies.length
  end

  test "should remove supported frequency" do
    config = create_valid_config(
      supported_billing_frequencies: [ "monthly", "quarterly", "yearly" ],
      default_billing_frequencies: [ "monthly" ]
    )

    config.remove_supported_frequency!("yearly")
    config.reload

    assert_not config.supports_frequency?("yearly")
    assert_not_includes config.supported_billing_frequencies, "yearly"
  end

  test "should not remove frequency if it is default" do
    config = create_valid_config

    config.remove_supported_frequency!("monthly")
    config.reload

    assert config.supports_frequency?("monthly")
  end

  test "should export configuration hash" do
    config = create_valid_config
    hash = config.to_configuration_hash

    assert_equal 3, hash[:generation][:months_ahead]
    assert_equal true, hash[:generation][:auto_enabled]
    assert_equal 6, hash[:archiving][:months_threshold]
    assert_equal 7, hash[:due_soon_days]
    assert_includes hash[:frequencies][:supported], "monthly"
    assert_equal [ "monthly" ], hash[:frequencies][:default]
    assert_equal [ 7, 3, 1 ], hash[:reminders][:schedule]
    assert_equal 5, hash[:reminders][:grace_period_days]
  end

  # Test JSON serialization
  test "should handle JSON serialization for arrays" do
    config = BillingConfig.create!(
      generation_months_ahead: 3,
      archiving_months_threshold: 6,
      due_soon_days: 7,
      auto_archiving_enabled: true,
      auto_generation_enabled: true,
      default_billing_frequencies: '["monthly"]',
      supported_billing_frequencies: '["monthly", "quarterly", "yearly"]',
      reminder_schedule: "[7, 3, 1]",
      payment_grace_period_days: 5
    )

    config.reload

    assert_equal [ "monthly" ], config.default_billing_frequencies
    assert_equal [ "monthly", "quarterly", "yearly" ], config.supported_billing_frequencies
    assert_equal [ 7, 3, 1 ], config.reminder_schedule
  end

  private

  def create_valid_config(attributes = {})
    default_attributes = {
      generation_months_ahead: 3,
      archiving_months_threshold: 6,
      due_soon_days: 7,
      auto_archiving_enabled: true,
      auto_generation_enabled: true,
      default_billing_frequencies: [ "monthly" ],
      supported_billing_frequencies: [ "monthly", "quarterly", "yearly" ],
      reminder_schedule: [ 7, 3, 1 ],
      payment_grace_period_days: 5
    }

    BillingConfig.create!(default_attributes.merge(attributes))
  end
end
