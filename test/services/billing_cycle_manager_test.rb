require "test_helper"

class BillingCycleManagerTest < ActiveSupport::TestCase
  def setup
    # Clean up any existing configs and create fresh test data
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

    @project = projects(:netflix)
    @manager = BillingCycleManager.new(@project)
  end

  def teardown
    BillingConfig.delete_all
  end

  # Test initialization
  test "should initialize with project and config" do
    assert_equal @project, @manager.project
    assert_equal @config, @manager.config
    assert_instance_of BillingConfig, @manager.config
  end

  # Test cycle generation
  test "should generate upcoming cycles when auto generation enabled" do
    initial_count = @project.billing_cycles.count

    created_cycles = @manager.generate_upcoming_cycles

    assert created_cycles.is_a?(Array)
    assert @project.billing_cycles.count > initial_count

    created_cycles.each do |cycle|
      assert cycle.persisted?
      assert_equal @project, cycle.project
      assert_not cycle.archived?
      assert cycle.due_date > Date.current
    end
  end

    test "should not generate cycles when auto generation disabled" do
    @config.update!(auto_generation_enabled: false)
    @manager = BillingCycleManager.new(@project)  # Reload manager with new config

    initial_count = @project.billing_cycles.count
    created_cycles = @manager.generate_upcoming_cycles

    assert_equal [], created_cycles
    assert_equal initial_count, @project.billing_cycles.count
  end

  test "should not duplicate existing cycles" do
    # Create a cycle for next month
    next_month = 1.month.from_now.to_date
    existing_cycle = @project.billing_cycles.create!(
      due_date: next_month,
      total_amount: 100.0,
      archived: false
    )

    initial_count = @project.billing_cycles.count
    @manager.generate_upcoming_cycles

    # Should not create duplicate for the same due date
    duplicate_cycles = @project.billing_cycles.where(due_date: next_month)
    assert_equal 1, duplicate_cycles.count
  end

    # Test cycle archiving
    test "should archive old cycles when auto archiving enabled" do
    # Create old cycles that should be archived (bypass validation for test data)
    old_cycle = @project.billing_cycles.new(
      due_date: 7.months.ago.to_date,
      total_amount: 100.0,
      archived: false
    )
    old_cycle.save!(validate: false)

    recent_cycle = @project.billing_cycles.new(
      due_date: 1.month.ago.to_date,
      total_amount: 100.0,
      archived: false
    )
    recent_cycle.save!(validate: false)

    archived_count = @manager.archive_old_cycles

    assert archived_count > 0
    assert old_cycle.reload.archived?
    assert_not recent_cycle.reload.archived?
  end

      test "should not archive cycles when auto archiving disabled" do
    @config.update!(auto_archiving_enabled: false)
    @manager = BillingCycleManager.new(@project)  # Reload manager with new config

    old_cycle = @project.billing_cycles.new(
      due_date: 7.months.ago.to_date,
      total_amount: 100.0,
      archived: false
    )
    old_cycle.save!(validate: false)

    archived_count = @manager.archive_old_cycles

    assert_equal 0, archived_count
    assert_not old_cycle.reload.archived?
  end

  # Test due soon cycles
  test "should get due soon cycles correctly" do
    # Create cycles with different due dates
    due_soon = @project.billing_cycles.create!(
      due_date: 5.days.from_now.to_date,
      total_amount: 100.0,
      archived: false
    )

    due_later = @project.billing_cycles.create!(
      due_date: 10.days.from_now.to_date,
      total_amount: 100.0,
      archived: false
    )

    archived_cycle = @project.billing_cycles.create!(
      due_date: 3.days.from_now.to_date,
      total_amount: 100.0,
      archived: true
    )

    due_soon_cycles = @manager.get_due_soon_cycles

    assert_includes due_soon_cycles, due_soon
    assert_not_includes due_soon_cycles, due_later
    assert_not_includes due_soon_cycles, archived_cycle
  end

    # Test overdue cycles
    test "should get overdue cycles correctly" do
    grace_cutoff = @config.payment_grace_period_days.days.ago.to_date

    overdue_cycle = @project.billing_cycles.new(
      due_date: grace_cutoff - 1.day,
      total_amount: 100.0,
      archived: false
    )
    overdue_cycle.save!(validate: false)

    recent_cycle = @project.billing_cycles.new(
      due_date: 1.day.ago.to_date,
      total_amount: 100.0,
      archived: false
    )
    recent_cycle.save!(validate: false)

    overdue_cycles = @manager.get_overdue_cycles

    assert_includes overdue_cycles, overdue_cycle
    assert_not_includes overdue_cycles, recent_cycle
  end

  # Test date calculations
  test "should calculate next due date correctly for different frequencies" do
    base_date = Date.new(2025, 1, 15)

    weekly = @manager.calculate_next_due_date(base_date, "weekly")
    assert_equal Date.new(2025, 1, 22), weekly

    monthly = @manager.calculate_next_due_date(base_date, "monthly")
    assert_equal Date.new(2025, 2, 15), monthly

    quarterly = @manager.calculate_next_due_date(base_date, "quarterly")
    assert_equal Date.new(2025, 4, 15), quarterly

    yearly = @manager.calculate_next_due_date(base_date, "yearly")
    assert_equal Date.new(2026, 1, 15), yearly
  end

  test "should use default frequency when none specified" do
    base_date = Date.current
    next_date = @manager.calculate_next_due_date(base_date)

    # Should default to monthly (from config)
    expected_date = @manager.calculate_next_due_date(base_date, "monthly")
    assert_equal expected_date, next_date
  end

  test "should fallback to monthly for invalid frequency" do
    base_date = Date.current
    next_date = @manager.calculate_next_due_date(base_date, "invalid")

    expected_date = base_date + 1.month
    assert_equal expected_date, next_date
  end

    # Test amount calculation
    test "should calculate total amount for cycle" do
    due_date = 1.month.from_now.to_date

    # Test with project cost
    @project.update!(cost: 120.0)
    amount = @manager.calculate_total_amount_for_cycle(due_date)
    assert_equal 120.0, amount
  end

      test "should return zero when no project cost" do
    # Create a new project without cost validation for this test
    project_without_cost = Project.new(name: "Test", cost: 0, billing_cycle: "monthly", renewal_date: Date.current, reminder_days: 7, user: @project.user, slug: "9876543210")
    project_without_cost.save!(validate: false)

    manager = BillingCycleManager.new(project_without_cost)
    due_date = 1.month.from_now.to_date

    amount = manager.calculate_total_amount_for_cycle(due_date)
    assert_equal 0, amount
  end

    # Test statistics
    test "should provide cycle statistics" do
    # Clear existing cycles and create test cycles (bypass validation for past dates)
    @project.billing_cycles.destroy_all

    past_cycle = @project.billing_cycles.new(due_date: 1.month.ago, total_amount: 100, archived: true)
    past_cycle.save!(validate: false)

    @project.billing_cycles.create!(due_date: Date.current, total_amount: 100, archived: false)
    @project.billing_cycles.create!(due_date: 5.days.from_now, total_amount: 100, archived: false)
    @project.billing_cycles.create!(due_date: 2.months.from_now, total_amount: 100, archived: false)

    stats = @manager.get_cycle_statistics

    assert_equal 4, stats[:total_cycles]
    assert_equal 3, stats[:active_cycles]
    assert_equal 1, stats[:archived_cycles]
    assert stats[:due_soon_count] >= 0
    assert stats[:upcoming_cycles] >= 0
    assert_instance_of Date, stats[:next_generation_date]
    assert_instance_of Date, stats[:next_archiving_cutoff]
  end

  # Test validation
  test "should validate cycle data correctly" do
    # Valid cycle data
    valid_data = {
      due_date: 1.month.from_now.to_date,
      total_amount: 100.0
    }

    errors = @manager.validate_cycle_data(valid_data)
    assert_empty errors

    # Invalid cycle data
    invalid_data = {
      due_date: nil,
      total_amount: -50.0
    }

    errors = @manager.validate_cycle_data(invalid_data)
    assert_includes errors, "Due date is required"
    assert_includes errors, "Total amount must be non-negative"
  end

  test "should detect duplicate due dates in validation" do
    due_date = 1.month.from_now.to_date

    # Create existing cycle
    @project.billing_cycles.create!(
      due_date: due_date,
      total_amount: 100.0,
      archived: false
    )

    # Try to validate duplicate
    cycle_data = { due_date: due_date, total_amount: 50.0 }
    errors = @manager.validate_cycle_data(cycle_data)

    assert_includes errors, "Billing cycle already exists for this due date"
  end

  test "should reject past due dates in validation" do
    past_date = 1.day.ago.to_date
    cycle_data = { due_date: past_date, total_amount: 100.0 }

    errors = @manager.validate_cycle_data(cycle_data)
    assert_includes errors, "Due date cannot be in the past"
  end

    # Test capability checks
    test "should check generation capability correctly" do
    assert @manager.can_generate_cycles?

    @config.update!(auto_generation_enabled: false)
    @manager = BillingCycleManager.new(@project)  # Reload manager with new config
    assert_not @manager.can_generate_cycles?
  end

  test "should check archiving capability correctly" do
    assert @manager.can_archive_cycles?

    @config.update!(auto_archiving_enabled: false)
    @manager = BillingCycleManager.new(@project)  # Reload manager with new config
    assert_not @manager.can_archive_cycles?
  end

  # Test configuration access
  test "should provide current configuration" do
    config_hash = @manager.current_configuration

    assert_equal 3, config_hash[:generation][:months_ahead]
    assert_equal true, config_hash[:generation][:auto_enabled]
    assert_equal 6, config_hash[:archiving][:months_threshold]
    assert_equal 7, config_hash[:due_soon_days]
  end

  # Test project frequency update
  test "should update project frequency when supported" do
    result = @manager.update_project_frequency("quarterly")
    assert result

    # Test with unsupported frequency
    result = @manager.update_project_frequency("invalid")
    assert_not result
  end

  # Test reminder processing
  test "should process cycle reminders" do
    # Create cycles due on reminder dates
    7.days.from_now.to_date.tap do |due_date|
      @project.billing_cycles.create!(
        due_date: due_date,
        total_amount: 100.0,
        archived: false
      )
    end

    reminder_cycles = @manager.process_cycle_reminders

    assert reminder_cycles.is_a?(Array)
    reminder_cycles.each do |reminder_data|
      assert reminder_data.key?(:cycle)
      assert reminder_data.key?(:days_before)
      assert_instance_of BillingCycle, reminder_data[:cycle]
      assert reminder_data[:days_before].is_a?(Integer)
    end
  end

  # Test backward compatibility methods
  test "should provide sync methods for existing services" do
    # These methods should exist for backward compatibility
    assert_respond_to @manager, :sync_with_existing_generator
    assert_respond_to @manager, :sync_with_existing_archiver

    # Should handle errors gracefully
    assert_nothing_raised do
      @manager.sync_with_existing_generator
      @manager.sync_with_existing_archiver
    end
  end

  # New tests for configurable billing frequencies
  test "should use project billing frequency" do
    @project.update!(billing_cycle: "weekly")
    assert_equal "weekly", @manager.project_billing_frequency

    # Test fallback to config default when project has no frequency
    @project.update_column(:billing_cycle, nil) # Use update_column to bypass validation
    assert_equal "monthly", @manager.project_billing_frequency
  end

  test "should calculate next due date with daily frequency" do
    @project.update!(billing_cycle: "daily")
    base_date = Date.new(2024, 1, 15)

    next_date = @manager.calculate_next_due_date(base_date)
    assert_equal Date.new(2024, 1, 16), next_date
  end

  test "should calculate next due date with weekly frequency" do
    @project.update!(billing_cycle: "weekly")
    base_date = Date.new(2024, 1, 15)

    next_date = @manager.calculate_next_due_date(base_date)
    assert_equal Date.new(2024, 1, 22), next_date
  end

  test "should use project frequency for cycle generation" do
    @project.update!(billing_cycle: "quarterly")
    @project.billing_cycles.destroy_all # Clear existing cycles

    created_cycles = @manager.generate_upcoming_cycles

    # Should generate quarterly cycles, not monthly
    assert created_cycles.length > 0

    # Check that cycles are spaced quarterly
    sorted_cycles = created_cycles.sort_by(&:due_date)
    if sorted_cycles.length >= 2
      first_date = sorted_cycles[0].due_date
      second_date = sorted_cycles[1].due_date
      expected_gap = 3.months
      actual_gap = (second_date - first_date).to_i # Convert to integer days

      # Allow some tolerance for month length differences (about 90 days ± 5)
      assert_in_delta 90, actual_gap, 5, "Quarterly cycles should be ~90 days apart, got #{actual_gap} days"
    end
  end

  test "should validate frequency compatibility" do
    # Test supported frequency
    assert @manager.can_use_frequency?("weekly")
    assert @manager.can_use_frequency?("daily")

    # Test unsupported frequency (temporarily remove from config)
    @config.update!(supported_billing_frequencies: [ "monthly", "quarterly" ])
    @manager = BillingCycleManager.new(@project) # Reload

    assert_not @manager.can_use_frequency?("weekly")
    assert_not @manager.can_use_frequency?("daily")
  end

  test "should update project frequency through manager" do
    original_frequency = @project.billing_cycle

    # Test successful update
    result = @manager.update_project_frequency!("weekly")
    assert result
    assert_equal "weekly", @project.reload.billing_cycle

    # Test failed update with unsupported frequency
    result = @manager.update_project_frequency!("invalid")
    assert_not result
    assert_equal "weekly", @project.reload.billing_cycle # Should remain unchanged
  end

  test "should provide frequency generation settings" do
    @project.update!(billing_cycle: "weekly")
    settings = @manager.frequency_generation_settings

    assert_equal "weekly", settings[:frequency]
    assert_equal 7, settings[:period_days]
    assert settings[:cycles_per_generation_period] > 0
    assert settings[:max_cycles_to_generate] > 0
  end

  test "should calculate cycles per generation period correctly" do
    generation_months = @config.generation_months_ahead

    test_cases = {
      "daily" => generation_months * 30,
      "weekly" => generation_months * 4,
      "monthly" => generation_months,
      "quarterly" => (generation_months / 3.0).ceil,
      "yearly" => (generation_months / 12.0).ceil
    }

    test_cases.each do |frequency, expected_cycles|
      @project.update!(billing_cycle: frequency)
      cycles = @manager.send(:calculate_cycles_per_generation_period, frequency)
      assert_equal expected_cycles, cycles, "#{frequency} should generate #{expected_cycles} cycles"
    end
  end

  test "should apply safety limits for cycle generation" do
    test_cases = {
      "daily" => 200,
      "weekly" => 52,
      "monthly" => 24,
      "quarterly" => 12,
      "yearly" => 5
    }

    test_cases.each do |frequency, expected_limit|
      limit = @manager.send(:calculate_max_cycles_for_frequency, frequency)
      assert_equal expected_limit, limit, "#{frequency} should have limit of #{expected_limit}"
    end
  end

  test "should respect safety limits during generation" do
    @project.update!(billing_cycle: "daily")
    @project.billing_cycles.destroy_all

    # Generate cycles - should not exceed daily limit of 200
    created_cycles = @manager.generate_upcoming_cycles
    assert created_cycles.length <= 200, "Daily cycle generation should not exceed safety limit"
  end

  test "should generate appropriate number of cycles for different frequencies" do
    frequencies_to_test = [ "weekly", "monthly", "quarterly" ]

    frequencies_to_test.each do |frequency|
      @project.update!(billing_cycle: frequency)
      @project.billing_cycles.destroy_all

      created_cycles = @manager.generate_upcoming_cycles

      # Should generate some cycles but not too many
      assert created_cycles.length > 0, "#{frequency} should generate some cycles"
      assert created_cycles.length <= 50, "#{frequency} should not generate excessive cycles"

      # All cycles should be in the future
      created_cycles.each do |cycle|
        assert cycle.due_date > Date.current, "Generated cycles should be in the future"
      end
    end
  end

  test "should handle missing cycles calculation with project frequency" do
    @project.update!(billing_cycle: "weekly")
    @project.billing_cycles.destroy_all

    end_date = 2.months.from_now.to_date
    existing_cycles = @project.billing_cycles.none

    missing_cycles = @manager.send(:calculate_missing_cycles, end_date, existing_cycles)

    assert missing_cycles.length > 0
    assert missing_cycles.length <= 52 # Weekly safety limit

    # Check that cycles are spaced weekly
    if missing_cycles.length >= 2
      first_date = missing_cycles[0][:due_date]
      second_date = missing_cycles[1][:due_date]
      gap_days = (second_date - first_date).to_i # Convert to integer
      assert_equal 7, gap_days, "Weekly cycles should be 7 days apart"
    end
  end

  private

  def create_test_cycles
    [
      { due_date: 1.month.ago.to_date, archived: true },
      { due_date: Date.current, archived: false },
      { due_date: 5.days.from_now.to_date, archived: false },
      { due_date: 2.months.from_now.to_date, archived: false }
    ].each do |attrs|
      @project.billing_cycles.create!(
        due_date: attrs[:due_date],
        total_amount: 100.0,
        archived: attrs[:archived]
      )
    end
  end
end
