require "test_helper"

class BillingGenerationPolicyTest < ActiveSupport::TestCase
  def setup
    # Clean up existing data
    BillingConfig.destroy_all
    User.destroy_all
    Project.destroy_all
    @config = BillingConfig.create!(
      auto_generation_enabled: true,
      generation_months_ahead: 3,
      auto_archiving_enabled: true,
      archiving_months_threshold: 6,
      reminders_enabled: true,
      gentle_reminder_days_before: 3,
      standard_reminder_days_overdue: 1,
      urgent_reminder_days_overdue: 7,
      final_notice_days_overdue: 14,
      payment_grace_period_days: 5,
      supported_billing_frequencies: [ "monthly", "quarterly" ],
      default_frequency: "monthly"
    )

    # Create test user and project - skip validation for tests
    @user = User.new(email_address: "test@example.com", first_name: "Test", last_name: "User")
    @user.save!(validate: false)

    @project = Project.new(
      name: "Test Subscription",
      cost: 15.99,
      billing_cycle: "monthly",
      renewal_date: Date.current + 1.month,
      reminder_days: 7,
      user: @user
    )
    @project.save!(validate: false)

    @policy = BillingGenerationPolicy.new(@config, @project)
  end

  test "should initialize with config and project" do
    assert_equal @config, @policy.config
    assert_equal @project, @policy.project
  end

  test "should generate cycles when auto generation is enabled and project allows" do
    assert @policy.should_generate_cycles?
  end

  test "should not generate cycles when auto generation is disabled" do
    @config.update!(auto_generation_enabled: false)
    refute @policy.should_generate_cycles?
  end

  test "should not generate cycles when project is nil" do
    policy = BillingGenerationPolicy.new(@config, nil)
    refute policy.should_generate_cycles?
  end

  test "should not generate cycles when project has invalid frequency" do
    @project.update!(billing_cycle: "unsupported")
    refute @policy.should_generate_cycles?
  end

  test "should not generate cycles when project has no cost" do
    @project.update!(cost: nil)
    refute @policy.should_generate_cycles?
  end

  test "should calculate generation end date from config" do
    expected_date = Date.current + @config.generation_months_ahead.months
    assert_equal expected_date, @policy.generation_end_date
  end

  test "should determine if cycle needed for specific date" do
    future_date = Date.current + 1.month
    assert @policy.needs_cycle_for_date?(future_date)
  end

  test "should not need cycle for past date" do
    past_date = Date.current - 1.day
    refute @policy.needs_cycle_for_date?(past_date)
  end

  test "should not need cycle beyond generation end date" do
    far_future_date = Date.current + 1.year
    refute @policy.needs_cycle_for_date?(far_future_date)
  end

  test "should not need cycle if one already exists" do
    future_date = Date.current + 1.month
    BillingCycle.create!(
      project: @project,
      due_date: future_date,
      total_amount: 15.99,
      archived: false
    )

    refute @policy.needs_cycle_for_date?(future_date)
  end

  test "should calculate next due date for monthly frequency" do
    start_date = Date.current
    next_date = @policy.next_due_date(start_date, "monthly")
    assert_equal start_date + 1.month, next_date
  end

  test "should calculate next due date for quarterly frequency" do
    start_date = Date.current
    next_date = @policy.next_due_date(start_date, "quarterly")
    assert_equal start_date + 3.months, next_date
  end

  test "should calculate next due date for weekly frequency" do
    start_date = Date.current
    next_date = @policy.next_due_date(start_date, "weekly")
    assert_equal start_date + 1.week, next_date
  end

  test "should default to monthly for unknown frequency" do
    start_date = Date.current
    next_date = @policy.next_due_date(start_date, "unknown")
    assert_equal start_date + 1.month, next_date
  end

  test "should use project frequency when none specified" do
    @project.update!(billing_cycle: "quarterly")
    start_date = Date.current
    next_date = @policy.next_due_date(start_date)
    assert_equal start_date + 3.months, next_date
  end

  test "should use config default frequency as fallback" do
    @project.update!(billing_cycle: nil)
    start_date = Date.current
    next_date = @policy.next_due_date(start_date)
    assert_equal start_date + 1.month, next_date
  end

  test "should generate cycle data for valid date" do
    future_date = Date.current + 1.month
    cycle_data = @policy.generate_cycle_data(future_date)

    assert_not_nil cycle_data
    assert_equal future_date, cycle_data[:due_date]
    assert_equal @project.cost, cycle_data[:total_amount]
    assert_equal false, cycle_data[:archived]
    assert_equal @project, cycle_data[:project]
  end

  test "should return nil cycle data for invalid date" do
    past_date = Date.current - 1.day
    cycle_data = @policy.generate_cycle_data(past_date)
    assert_nil cycle_data
  end

  test "should calculate cycles to generate count" do
    # Should generate 3 monthly cycles (config months ahead = 3)
    count = @policy.cycles_to_generate
    assert count > 0
    assert count <= 3
  end

  test "should return zero cycles when generation disabled" do
    @config.update!(auto_generation_enabled: false)
    count = @policy.cycles_to_generate
    assert_equal 0, count
  end

  test "should generate missing cycles data" do
    missing_cycles = @policy.missing_cycles_data
    assert missing_cycles.is_a?(Array)
    assert missing_cycles.length > 0

    # First cycle should be for next month
    first_cycle = missing_cycles.first
    assert first_cycle[:due_date] > Date.current
    assert_equal @project.cost, first_cycle[:total_amount]
  end

  test "should return empty array when generation not allowed" do
    @config.update!(auto_generation_enabled: false)
    missing_cycles = @policy.missing_cycles_data
    assert_equal [], missing_cycles
  end

  test "should validate generation rules" do
    errors = @policy.validate_generation_rules
    assert_equal [], errors
  end

  test "should validate and report missing project" do
    policy = BillingGenerationPolicy.new(@config, nil)
    errors = policy.validate_generation_rules
    assert_includes errors, "Project is required for cycle generation"
  end

  test "should validate and report disabled auto generation" do
    @config.update!(auto_generation_enabled: false)
    errors = @policy.validate_generation_rules
    assert_includes errors, "Auto generation is disabled"
  end

  test "should validate and report invalid project frequency" do
    @project.update!(billing_cycle: "invalid")
    errors = @policy.validate_generation_rules
    assert_includes errors, "Project has invalid billing frequency"
  end

  test "should validate and report missing project cost" do
    @project.update!(cost: nil)
    errors = @policy.validate_generation_rules
    assert_includes errors, "Project cost must be positive"
  end

  test "should detect duplicate cycles" do
    future_date = Date.current + 1.month
    cycles_data = [ { due_date: future_date, total_amount: 15.99 } ]

    # Create existing cycle
    BillingCycle.create!(
      project: @project,
      due_date: future_date,
      total_amount: 15.99,
      archived: false
    )

    assert @policy.would_create_duplicates?(cycles_data)
  end

  test "should not detect duplicates for empty cycles data" do
    refute @policy.would_create_duplicates?([])
  end

  test "should not detect duplicates for unique dates" do
    future_date = Date.current + 2.months
    cycles_data = [ { due_date: future_date, total_amount: 15.99 } ]

    refute @policy.would_create_duplicates?(cycles_data)
  end

  test "should provide generation summary" do
    summary = @policy.generation_summary

    assert_includes summary, :enabled
    assert_includes summary, :project_frequency
    assert_includes summary, :generation_end_date
    assert_includes summary, :cycles_needed
    assert_includes summary, :validation_errors

    assert_equal true, summary[:enabled]
    assert_equal "monthly", summary[:project_frequency]
    assert summary[:cycles_needed] > 0
    assert_equal [], summary[:validation_errors]
  end

  test "should handle missing cycles calculation correctly" do
    # Create one existing cycle
    existing_date = Date.current + 1.month
    BillingCycle.create!(
      project: @project,
      due_date: existing_date,
      total_amount: 15.99,
      archived: false
    )

    missing_cycles = @policy.missing_cycles_data

    # Should generate additional cycles beyond the existing one
    assert missing_cycles.length > 0
    refute missing_cycles.any? { |cycle| cycle[:due_date] == existing_date }
  end

  test "should handle edge case with existing cycles beyond end date" do
    # Create cycle beyond generation end date
    far_future_date = Date.current + 1.year
    BillingCycle.create!(
      project: @project,
      due_date: far_future_date,
      total_amount: 15.99,
      archived: false
    )

    missing_cycles = @policy.missing_cycles_data

    # Should still generate cycles within the normal range
    assert missing_cycles.length > 0
    assert missing_cycles.all? { |cycle| cycle[:due_date] <= @policy.generation_end_date }
  end

  test "should calculate proper amount for cycles" do
    future_date = Date.current + 1.month
    cycle_data = @policy.generate_cycle_data(future_date)

    # Basic calculation should match project cost
    assert_equal @project.cost, cycle_data[:total_amount]
  end

  test "should handle zero cost projects" do
    @project.update!(cost: 0)
    refute @policy.should_generate_cycles?
  end

  test "should handle negative cost projects" do
    @project.update!(cost: -10)
    refute @policy.should_generate_cycles?
  end
end
