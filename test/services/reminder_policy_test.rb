require "test_helper"

class ReminderPolicyTest < ActiveSupport::TestCase
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

    @policy = ReminderPolicy.new(@config, @project)
  end

  test "should initialize with config and project" do
    assert_equal @config, @policy.config
    assert_equal @project, @policy.project
  end

  test "should send reminders when enabled and project present" do
    assert @policy.should_send_reminders?
  end

  test "should not send reminders when disabled" do
    @config.update!(reminders_enabled: false)
    refute @policy.should_send_reminders?
  end

  test "should not send reminders when project is nil" do
    policy = ReminderPolicy.new(@config, nil)
    refute policy.should_send_reminders?
  end

  test "should determine gentle reminder type for upcoming due date" do
    future_date = Date.current + 2.days # Within gentle reminder window
    cycle = create_test_cycle(future_date)

    reminder_type = @policy.reminder_type_for_cycle(cycle)
    assert_equal :gentle_reminder, reminder_type
  end

  test "should determine standard reminder type for recent overdue" do
    overdue_date = Date.current - 2.days # Within standard reminder window
    cycle = create_test_cycle(overdue_date)

    reminder_type = @policy.reminder_type_for_cycle(cycle)
    assert_equal :standard_reminder, reminder_type
  end

  test "should determine urgent reminder type for moderately overdue" do
    overdue_date = Date.current - 10.days # Within urgent reminder window
    cycle = create_test_cycle(overdue_date)

    reminder_type = @policy.reminder_type_for_cycle(cycle)
    assert_equal :urgent_reminder, reminder_type
  end

  test "should determine final notice type for severely overdue" do
    overdue_date = Date.current - 20.days # Beyond final notice threshold
    cycle = create_test_cycle(overdue_date)

    reminder_type = @policy.reminder_type_for_cycle(cycle)
    assert_equal :final_notice, reminder_type
  end

  test "should return nil reminder type for dates outside windows" do
    # Too far in future
    far_future_date = Date.current + 10.days
    cycle = create_test_cycle(far_future_date)

    reminder_type = @policy.reminder_type_for_cycle(cycle)
    assert_nil reminder_type
  end

  test "should send reminder for valid cycle" do
    due_soon_date = Date.current + 2.days
    cycle = create_test_cycle(due_soon_date)

    assert @policy.should_send_reminder?(cycle)
  end

  test "should not send reminder for archived cycle" do
    due_soon_date = Date.current + 2.days
    cycle = create_test_cycle(due_soon_date, archived: true)

    refute @policy.should_send_reminder?(cycle)
  end

  test "should not send reminder for fully paid cycle" do
    due_soon_date = Date.current + 2.days
    cycle = create_test_cycle(due_soon_date)
    cycle.define_singleton_method(:fully_paid?) { true }

    refute @policy.should_send_reminder?(cycle)
  end

  test "should not send reminder when reminders disabled" do
    @config.update!(reminders_enabled: false)
    due_soon_date = Date.current + 2.days
    cycle = create_test_cycle(due_soon_date)

    refute @policy.should_send_reminder?(cycle)
  end

  test "should find cycles needing reminders" do
    # Create cycles in various states
    due_soon = create_test_cycle(Date.current + 2.days) # Should need gentle reminder
    overdue = create_test_cycle(Date.current - 3.days) # Should need standard reminder
    far_future = create_test_cycle(Date.current + 10.days) # Should not need reminder

    cycles_needing = @policy.cycles_needing_reminders
    assert_includes cycles_needing, due_soon
    assert_includes cycles_needing, overdue
    refute_includes cycles_needing, far_future
  end

  test "should return empty collection when reminders disabled" do
    @config.update!(reminders_enabled: false)
    create_test_cycle(Date.current + 2.days)

    cycles_needing = @policy.cycles_needing_reminders
    assert_equal 0, cycles_needing.count
  end

  test "should generate reminder data for cycle" do
    due_soon_date = Date.current + 2.days
    cycle = create_test_cycle(due_soon_date)

    reminder_data = @policy.reminder_data_for_cycle(cycle)

    assert_not_nil reminder_data
    assert_equal cycle, reminder_data[:cycle]
    assert_equal :gentle_reminder, reminder_data[:reminder_type]
    assert_equal 1, reminder_data[:urgency_level] # Gentle reminder urgency
    assert_equal 2, reminder_data[:days_until_due]
    assert_equal 0, reminder_data[:days_overdue]
    assert_includes reminder_data, :escalation_date
    assert_includes reminder_data, :recipients
    assert_includes reminder_data, :custom_message
  end

  test "should return nil reminder data for invalid cycle" do
    far_future_date = Date.current + 10.days
    cycle = create_test_cycle(far_future_date)

    reminder_data = @policy.reminder_data_for_cycle(cycle)
    assert_nil reminder_data
  end

  test "should generate pending reminders list" do
    # Create cycles that need reminders
    due_soon = create_test_cycle(Date.current + 2.days)
    overdue = create_test_cycle(Date.current - 3.days)

    pending = @policy.pending_reminders
    assert_equal 2, pending.length

    # Verify data structure
    pending.each do |reminder_data|
      assert_includes reminder_data, :cycle
      assert_includes reminder_data, :reminder_type
      assert_includes reminder_data, :urgency_level
    end
  end

  test "should validate reminder rules" do
    errors = @policy.validate_reminder_rules
    assert_equal [], errors
  end

  test "should validate and report missing project" do
    policy = ReminderPolicy.new(@config, nil)
    errors = policy.validate_reminder_rules
    assert_includes errors, "Project is required for reminders"
  end

  test "should validate and report disabled reminders" do
    @config.update!(reminders_enabled: false)
    errors = @policy.validate_reminder_rules
    assert_includes errors, "Reminders are disabled"
  end

  test "should validate reminder timing configuration" do
    @config.update!(
      gentle_reminder_days_before: 0,
      standard_reminder_days_overdue: -1
    )
    errors = @policy.validate_reminder_rules
    assert_includes errors, "Gentle reminder days must be positive"
    assert_includes errors, "Standard reminder days must be positive"
  end

  test "should validate logical order of reminders" do
    @config.update!(
      standard_reminder_days_overdue: 10,
      urgent_reminder_days_overdue: 5, # Should be after standard
      final_notice_days_overdue: 3    # Should be after urgent
    )
    errors = @policy.validate_reminder_rules
    assert_includes errors, "Standard reminder should come before urgent reminder"
    assert_includes errors, "Urgent reminder should come before final notice"
  end

  test "should check if reminder can be sent now based on frequency limits" do
    cycle = create_test_cycle(Date.current + 2.days)

    # Should be able to send first reminder
    assert @policy.can_send_reminder_now?(cycle, :gentle_reminder)
  end

  test "should provide reminder summary" do
    # Create some cycles needing reminders
    create_test_cycle(Date.current + 2.days) # Gentle reminder
    create_test_cycle(Date.current - 3.days) # Standard reminder

    summary = @policy.reminder_summary

    assert_includes summary, :enabled
    assert_includes summary, :pending_count
    assert_includes summary, :reminder_breakdown
    assert_includes summary, :validation_errors

    assert_equal true, summary[:enabled]
    assert_equal 2, summary[:pending_count]
    assert_equal [], summary[:validation_errors]
  end

  test "should preview reminders without sending" do
    due_soon = create_test_cycle(Date.current + 2.days)
    overdue = create_test_cycle(Date.current - 3.days)

    preview = @policy.preview_reminders
    assert_equal 2, preview.length

    preview.each do |preview_item|
      assert_includes preview_item, :cycle_id
      assert_includes preview_item, :due_date
      assert_includes preview_item, :reminder_type
      assert_includes preview_item, :urgency_level
      assert_includes preview_item, :days_until_due
      assert_includes preview_item, :days_overdue
      assert_includes preview_item, :recipient_count
      assert_includes preview_item, :can_send_now
    end
  end

  test "should determine if cycle is in grace period" do
    recently_overdue = create_test_cycle(Date.current - 2.days)
    assert @policy.in_grace_period?(recently_overdue)

    long_overdue = create_test_cycle(Date.current - 10.days)
    refute @policy.in_grace_period?(long_overdue)

    future_cycle = create_test_cycle(Date.current + 2.days)
    refute @policy.in_grace_period?(future_cycle)
  end

  test "should calculate next reminder date" do
    # Test gentle reminder escalation
    gentle_cycle = create_test_cycle(Date.current + 2.days)
    next_date = @policy.next_reminder_date(gentle_cycle)
    expected_date = gentle_cycle.due_date + @config.standard_reminder_days_overdue.days
    assert_equal expected_date, next_date

    # Test final notice (no next reminder)
    final_cycle = create_test_cycle(Date.current - 20.days)
    next_date = @policy.next_reminder_date(final_cycle)
    assert_nil next_date
  end

  test "should return nil next reminder date when reminders disabled" do
    @config.update!(reminders_enabled: false)
    cycle = create_test_cycle(Date.current + 2.days)

    next_date = @policy.next_reminder_date(cycle)
    assert_nil next_date
  end

  test "should generate context-aware custom messages" do
    # Test different reminder types
    gentle_cycle = create_test_cycle(Date.current + 2.days)
    gentle_data = @policy.reminder_data_for_cycle(gentle_cycle)
    assert_includes gentle_data[:custom_message], "friendly reminder"
    assert_includes gentle_data[:custom_message], @project.name

    overdue_cycle = create_test_cycle(Date.current - 3.days)
    overdue_data = @policy.reminder_data_for_cycle(overdue_cycle)
    assert_includes overdue_data[:custom_message], "days ago"
    assert_includes overdue_data[:custom_message], @project.name
  end

  test "should handle urgency levels correctly" do
    gentle_cycle = create_test_cycle(Date.current + 2.days)
    gentle_data = @policy.reminder_data_for_cycle(gentle_cycle)
    assert_equal 1, gentle_data[:urgency_level]

    urgent_cycle = create_test_cycle(Date.current - 10.days)
    urgent_data = @policy.reminder_data_for_cycle(urgent_cycle)
    assert_equal 3, urgent_data[:urgency_level]

    final_cycle = create_test_cycle(Date.current - 20.days)
    final_data = @policy.reminder_data_for_cycle(final_cycle)
    assert_equal 4, final_data[:urgency_level]
  end

  test "should calculate reminder breakdown correctly" do
    create_test_cycle(Date.current + 2.days) # Gentle
    create_test_cycle(Date.current - 3.days) # Standard
    create_test_cycle(Date.current - 10.days) # Urgent
    create_test_cycle(Date.current - 20.days) # Final

    summary = @policy.reminder_summary
    breakdown = summary[:reminder_breakdown]

    assert_equal 1, breakdown["gentle_reminder"]
    assert_equal 1, breakdown["standard_reminder"]
    assert_equal 1, breakdown["urgent_reminder"]
    assert_equal 1, breakdown["final_notice"]
  end

  test "should handle edge cases around reminder windows" do
    # Test cycle exactly at gentle reminder threshold
    exact_gentle = create_test_cycle(Date.current + @config.gentle_reminder_days_before.days)
    assert_equal :gentle_reminder, @policy.reminder_type_for_cycle(exact_gentle)

    # Test cycle exactly at standard reminder threshold
    exact_standard = create_test_cycle(Date.current - @config.standard_reminder_days_overdue.days)
    assert_equal :standard_reminder, @policy.reminder_type_for_cycle(exact_standard)
  end

  private

  def create_test_cycle(due_date, archived: false)
    cycle = BillingCycle.create!(
      project: @project,
      due_date: due_date,
      total_amount: 15.99,
      archived: archived
    )

    # Mock required methods for testing
    cycle.define_singleton_method(:fully_paid?) { false }
    cycle.define_singleton_method(:active_members) { [ @project ] } # Mock with project as member
    cycle.define_singleton_method(:last_reminder_of_type) { |type| nil } # No previous reminders

    cycle
  end
end
