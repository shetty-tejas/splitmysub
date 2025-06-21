require "test_helper"

class BillingArchivePolicyTest < ActiveSupport::TestCase
  # Helper method to create billing cycles with past dates (bypassing validation)
  def create_test_cycle(due_date:, archived: false, **attrs)
    cycle = BillingCycle.new(
      project: @project,
      due_date: due_date,
      total_amount: 15.99,
      archived: archived,
      **attrs
    )
    cycle.save!(validate: false)
    cycle
  end

  def setup
    # Use existing fixtures instead of creating new records
    @user = users(:test_user)
    @project = projects(:netflix)

    # Clean up existing billing configs and create one for testing
    BillingConfig.destroy_all
    BillingCycle.destroy_all
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
      default_billing_frequencies: [ "monthly" ],
      reminder_schedule: [ 7, 3, 1 ],
      due_soon_days: 7,
      default_frequency: "monthly"
    )

    @policy = BillingArchivePolicy.new(@config, @project)
  end

  test "should initialize with config and project" do
    assert_equal @config, @policy.config
    assert_equal @project, @policy.project
  end

  test "should archive cycles when auto archiving is enabled and project present" do
    assert @policy.should_archive_cycles?
  end

  test "should not archive cycles when auto archiving is disabled" do
    @config.update!(auto_archiving_enabled: false)
    refute @policy.should_archive_cycles?
  end

  test "should not archive cycles when project is nil" do
    policy = BillingArchivePolicy.new(@config, nil)
    refute policy.should_archive_cycles?
  end

  test "should calculate archiving cutoff date from config" do
    expected_date = Date.current - @config.archiving_months_threshold.months
    assert_equal expected_date, @policy.archiving_cutoff_date
  end

  test "should determine if cycle should be archived" do
    old_date = Date.current - 7.months
    cycle = create_test_cycle(due_date: old_date, archived: false)

    assert @policy.should_archive_cycle?(cycle)
  end

  test "should not archive already archived cycle" do
    old_date = Date.current - 7.months
    cycle = create_test_cycle(due_date: old_date, archived: true)

    refute @policy.should_archive_cycle?(cycle)
  end

  test "should not archive cycle newer than cutoff date" do
    recent_date = Date.current - 1.month
    cycle = create_test_cycle(due_date: recent_date, archived: false)

    refute @policy.should_archive_cycle?(cycle)
  end

  test "should not archive when archiving disabled" do
    @config.update!(auto_archiving_enabled: false)
    old_date = Date.current - 7.months
    cycle = create_test_cycle(due_date: old_date, archived: false)

    refute @policy.should_archive_cycle?(cycle)
  end

  test "should find archivable cycles" do
    # Create old cycles that should be archived
    old_cycle1 = create_test_cycle(due_date: Date.current - 7.months, archived: false)
    old_cycle2 = create_test_cycle(due_date: Date.current - 8.months, archived: false)

    # Create recent cycle that should not be archived
    recent_cycle = create_test_cycle(due_date: Date.current - 1.month, archived: false)

    archivable = @policy.archivable_cycles
    assert_includes archivable, old_cycle1
    assert_includes archivable, old_cycle2
    refute_includes archivable, recent_cycle
  end

  test "should return empty collection when archiving disabled" do
    @config.update!(auto_archiving_enabled: false)
    archivable = @policy.archivable_cycles
    assert_equal 0, archivable.count
  end

  test "should count archivable cycles correctly" do
    # Create multiple old cycles
    3.times do |i|
      create_test_cycle(due_date: Date.current - (7 + i).months, archived: false)
    end

    count = @policy.archivable_cycles_count
    assert_equal 3, count
  end

  test "should archive eligible cycles and return count" do
    # Create old cycles
    old_cycles = []
    3.times do |i|
      old_cycles << create_test_cycle(due_date: Date.current - (7 + i).months, archived: false)
    end

    archived_count = @policy.archive_eligible_cycles!
    assert_equal 3, archived_count

    # Verify cycles are now archived
    old_cycles.each(&:reload)
    old_cycles.each { |cycle| assert cycle.archived? }
  end

  test "should return zero when no cycles to archive" do
    archived_count = @policy.archive_eligible_cycles!
    assert_equal 0, archived_count
  end

  test "should validate archiving rules" do
    errors = @policy.validate_archiving_rules
    assert_equal [], errors
  end

  test "should validate and report missing project" do
    policy = BillingArchivePolicy.new(@config, nil)
    errors = policy.validate_archiving_rules
    assert_includes errors, "Project is required for cycle archiving"
  end

  test "should validate and report disabled auto archiving" do
    @config.update!(auto_archiving_enabled: false)
    errors = @policy.validate_archiving_rules
    assert_includes errors, "Auto archiving is disabled"
  end

  test "should validate and report invalid threshold" do
    # Mock the config to return an invalid threshold for testing
    @config.define_singleton_method(:archiving_months_threshold) { 0 }
    errors = @policy.validate_archiving_rules
    assert_includes errors, "Archiving threshold must be positive"
  end

  test "should determine if cycle can be safely archived" do
    old_date = Date.current - 7.months
    cycle = create_test_cycle(due_date: old_date, archived: false)

    # Mock fully_paid? method to return true
    cycle.define_singleton_method(:fully_paid?) { true }

    assert @policy.can_safely_archive?(cycle)
  end

  test "should not safely archive cycle that should not be archived" do
    recent_date = Date.current - 1.month
    cycle = create_test_cycle(due_date: recent_date, archived: false)

    refute @policy.can_safely_archive?(cycle)
  end

  test "should provide archiving summary" do
    # Create some archivable cycles
    2.times do |i|
      create_test_cycle(due_date: Date.current - (7 + i).months, archived: false)
    end

    summary = @policy.archiving_summary

    assert_includes summary, :enabled
    assert_includes summary, :cutoff_date
    assert_includes summary, :eligible_count
    assert_includes summary, :validation_errors

    assert_equal true, summary[:enabled]
    assert_equal 2, summary[:eligible_count]
    assert_equal [], summary[:validation_errors]
  end

  test "should preview archiving without actually archiving" do
    # Create old cycle
    old_cycle = create_test_cycle(due_date: Date.current - 7.months, archived: false)

    # Mock methods for preview
    old_cycle.define_singleton_method(:fully_paid?) { false }
    old_cycle.define_singleton_method(:payment_status) { "pending" }

    preview = @policy.preview_archiving
    assert_equal 1, preview.length

    preview_item = preview.first
    assert_equal old_cycle.id, preview_item[:cycle_id]
    assert_equal old_cycle.due_date, preview_item[:due_date]
    assert_equal old_cycle.total_amount, preview_item[:total_amount]
    assert_includes preview_item, :can_safely_archive
    assert_includes preview_item, :archive_reason
  end

  test "should return empty preview when archiving disabled" do
    @config.update!(auto_archiving_enabled: false)
    preview = @policy.preview_archiving
    assert_equal [], preview
  end

  test "should force archive cycle with reason" do
    cycle = create_test_cycle(due_date: Date.current - 1.month, archived: false)

    result = @policy.force_archive_cycle!(cycle, "Manual override")
    assert result

    cycle.reload
    assert cycle.archived?
    assert_equal "Manual override", cycle.adjustment_reason
    assert_not_nil cycle.archived_at
  end

  test "should not force archive already archived cycle" do
    cycle = create_test_cycle(due_date: Date.current - 7.months, archived: true)

    result = @policy.force_archive_cycle!(cycle)
    refute result
  end

  test "should not force archive nil cycle" do
    result = @policy.force_archive_cycle!(nil)
    refute result
  end

  test "should determine if cycle can be unarchived" do
    cycle = create_test_cycle(due_date: Date.current - 3.months, archived: true)

    assert @policy.can_unarchive_cycle?(cycle)
  end

  test "should not unarchive non-archived cycle" do
    cycle = create_test_cycle(due_date: Date.current - 3.months, archived: false)

    refute @policy.can_unarchive_cycle?(cycle)
  end

  test "should not unarchive very old cycle" do
    very_old_cycle = create_test_cycle(due_date: Date.current - 2.years, archived: true)

    refute @policy.can_unarchive_cycle?(very_old_cycle)
  end

  test "should unarchive cycle with reason" do
    cycle = create_test_cycle(due_date: Date.current - 3.months, archived: true, archived_at: 1.month.ago)

    result = @policy.unarchive_cycle!(cycle, "Dispute resolution")
    assert result

    cycle.reload
    refute cycle.archived?
    assert_nil cycle.archived_at
    assert_equal "Dispute resolution", cycle.adjustment_reason
  end

  test "should not unarchive cycle that cannot be unarchived" do
    very_old_cycle = create_test_cycle(due_date: Date.current - 2.years, archived: true)

    result = @policy.unarchive_cycle!(very_old_cycle)
    refute result

    very_old_cycle.reload
    assert very_old_cycle.archived?
  end

  test "should handle edge cases in archiving" do
    # Test with cycles exactly at cutoff date
    cutoff_date = @policy.archiving_cutoff_date
    cycle_at_cutoff = create_test_cycle(due_date: cutoff_date, archived: false)

    # Should not archive cycle exactly at cutoff (needs to be before cutoff)
    refute @policy.should_archive_cycle?(cycle_at_cutoff)
  end

  test "should properly calculate archive reasons" do
    # Create a cycle that's old enough to archive but paid (within grace period logic)
    old_cycle = create_test_cycle(due_date: Date.current - 7.months, archived: false)

    # Mock different payment states to test reason logic
    old_cycle.define_singleton_method(:fully_paid?) { true }

    preview = @policy.preview_archiving
    archive_item = preview.first
    # Since the cycle is 7 months old, it will be "Overdue beyond grace period"
    # even if fully paid, because the archive_reason method checks overdue status
    assert_includes archive_item[:archive_reason], "Overdue beyond grace period"
  end
end
