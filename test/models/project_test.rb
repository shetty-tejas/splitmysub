require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  def setup
    # Ensure we have a proper BillingConfig for testing
    BillingConfig.delete_all
    @config = BillingConfig.create!(
      generation_months_ahead: 3,
      archiving_months_threshold: 6,
      due_soon_days: 7,
      auto_archiving_enabled: true,
      auto_generation_enabled: true,
      default_billing_frequencies: [ "monthly" ],
      supported_billing_frequencies: [ "daily", "weekly", "monthly", "quarterly", "yearly" ],
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

  def teardown
    BillingConfig.delete_all
  end

  test "should belong to user" do
    project = projects(:netflix)
    assert_respond_to project, :user
    assert_instance_of User, project.user
  end

  test "should have required attributes" do
    project = projects(:netflix)
    assert_not_nil project.name
    assert_not_nil project.cost
    assert_not_nil project.billing_cycle
    assert_not_nil project.renewal_date
  end

  test "should be valid with valid attributes" do
    project = Project.new(
      name: "Test Service",
      cost: 10.99,
      billing_cycle: "monthly",
      renewal_date: 1.month.from_now,
      payment_instructions: "PayPal: test@example.com",
      reminder_days: 7,
      user: users(:test_user)
    )
    assert project.valid?
  end

  # New tests for configurable billing frequencies
  test "should validate billing_cycle against supported frequencies" do
    project = projects(:netflix)

    # Test supported frequencies
    %w[daily weekly monthly quarterly yearly].each do |frequency|
      project.billing_cycle = frequency
      assert project.valid?, "#{frequency} should be valid but got errors: #{project.errors.full_messages}"
    end

    # Test unsupported frequency
    project.billing_cycle = "invalid_frequency"
    assert_not project.valid?
    assert_includes project.errors[:billing_cycle], "invalid_frequency is not a supported billing frequency. Supported frequencies: daily, weekly, monthly, quarterly, yearly"
  end

  test "should calculate next billing date correctly for all frequencies" do
    project = projects(:netflix)
    base_date = Date.new(2024, 1, 15)

    test_cases = {
      "daily" => base_date + 1.day,
      "weekly" => base_date + 1.week,
      "monthly" => base_date + 1.month,
      "quarterly" => base_date + 3.months,
      "yearly" => base_date + 1.year
    }

    test_cases.each do |frequency, expected_date|
      project.billing_cycle = frequency
      assert_equal expected_date, project.calculate_next_billing_date(base_date),
                   "#{frequency} frequency should calculate correct next date"
    end
  end

  test "should calculate billing period days correctly" do
    project = projects(:netflix)

    expected_days = {
      "daily" => 1,
      "weekly" => 7,
      "monthly" => 30,
      "quarterly" => 90,
      "yearly" => 365
    }

    expected_days.each do |frequency, days|
      project.billing_cycle = frequency
      assert_equal days, project.billing_period_days,
                   "#{frequency} should return #{days} days"
    end
  end

  test "should calculate annual cost correctly for all frequencies" do
    project = projects(:netflix)
    project.cost = 10.0

    expected_costs = {
      "daily" => 10.0 * 365,
      "weekly" => 10.0 * 52,
      "monthly" => 10.0 * 12,
      "quarterly" => 10.0 * 4,
      "yearly" => 10.0
    }

    expected_costs.each do |frequency, expected_cost|
      project.billing_cycle = frequency
      assert_equal expected_cost, project.annual_cost,
                   "#{frequency} frequency should calculate correct annual cost"
    end
  end

  test "should return supported frequencies from BillingConfig" do
    project = projects(:netflix)
    config_frequencies = BillingConfig.current.supported_billing_frequencies

    assert_equal config_frequencies, project.supported_frequencies
  end

  test "should check if frequency is supported" do
    project = projects(:netflix)

    # Test supported frequencies
    %w[daily weekly monthly quarterly yearly].each do |frequency|
      assert project.can_use_frequency?(frequency), "#{frequency} should be supported"
    end

    # Test unsupported frequency
    assert_not project.can_use_frequency?("invalid"), "invalid frequency should not be supported"
  end

  test "should update billing frequency successfully" do
    project = projects(:netflix)
    original_frequency = project.billing_cycle

    # Test updating to a supported frequency
    result = project.update_billing_frequency!("weekly")
    assert result, "Should successfully update to weekly frequency"
    assert_equal "weekly", project.reload.billing_cycle

    # Test updating to unsupported frequency
    result = project.update_billing_frequency!("invalid")
    assert_not result, "Should fail to update to invalid frequency"
    assert_equal "weekly", project.reload.billing_cycle # Should remain unchanged
  end

  test "should display billing frequency in human readable format" do
    project = projects(:netflix)

    test_cases = {
      "daily" => "Daily",
      "weekly" => "Weekly",
      "monthly" => "Monthly",
      "quarterly" => "Quarterly",
      "yearly" => "Yearly"
    }

    test_cases.each do |frequency, expected_display|
      project.billing_cycle = frequency
      assert_equal expected_display, project.billing_frequency_display
    end
  end

  test "should handle legacy next_billing_cycle method" do
    project = projects(:netflix)
    project.renewal_date = Date.new(2024, 1, 15)

    # This should use the new calculate_next_billing_date method
    project.billing_cycle = "monthly"
    expected = Date.new(2024, 2, 15)
    assert_equal expected, project.next_billing_cycle
  end

  test "should fallback gracefully when BillingConfig is unavailable" do
    # Temporarily delete the config to simulate unavailability
    BillingConfig.delete_all

    project = Project.new(
      name: "Test Service",
      cost: 10.99,
      billing_cycle: "monthly",
      renewal_date: 1.month.from_now,
      payment_instructions: "PayPal: test@example.com",
      reminder_days: 7,
      user: users(:test_user)
    )

    # Should still be valid due to fallback validation
    assert project.valid?, "Should be valid with fallback validation"

    # Test with invalid frequency - the validation will create a default config
    # so we expect the config-based error message
    project.billing_cycle = "invalid"
    assert_not project.valid?
    # The error message will be the config-based one since a default config gets created
    error_message = project.errors[:billing_cycle].first
    assert error_message.include?("invalid is not a supported billing frequency"),
           "Expected config-based error message, got: #{error_message}"

    # Restore config for other tests
    setup
  end
end
