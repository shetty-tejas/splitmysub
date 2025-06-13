require "test_helper"

class BillingCycleArchiverServiceTest < ActiveSupport::TestCase
  def setup
    @project = projects(:netflix)
    @service = BillingCycleArchiverService.new(6)
  end

  test "should archive old fully paid cycles" do
    # Create old cycle by building and then updating to bypass validation
    old_cycle = @project.billing_cycles.build(
      due_date: Date.current,
      total_amount: 15.99
    )
    old_cycle.save!(validate: false)
    old_cycle.update_column(:due_date, 8.months.ago)

    # Make it fully paid
    old_cycle.payments.create!(
      user: users(:test_user),
      amount: 5.33,
      status: "confirmed",
      confirmation_date: Date.current
    )
    old_cycle.payments.create!(
      user: users(:member_user),
      amount: 5.33,
      status: "confirmed",
      confirmation_date: Date.current
    )
    old_cycle.payments.create!(
      user: users(:other_user),
      amount: 5.33,
      status: "confirmed",
      confirmation_date: Date.current
    )

    assert_not old_cycle.archived?

    archived_count = @service.archive_old_cycles

    assert_equal 1, archived_count
    assert old_cycle.reload.archived?
  end

  test "should archive very old unpaid cycles" do
    # Create very old cycle by building and then updating to bypass validation
    very_old_cycle = @project.billing_cycles.build(
      due_date: Date.current,
      total_amount: 15.99
    )
    very_old_cycle.save!(validate: false)
    very_old_cycle.update_column(:due_date, 2.years.ago)

    assert_not very_old_cycle.archived?

    archived_count = @service.archive_old_cycles

    assert_equal 1, archived_count
    assert very_old_cycle.reload.archived?
  end

  test "should not archive recent cycles" do
    # Create recent cycle by building and then updating to bypass validation
    recent_cycle = @project.billing_cycles.build(
      due_date: Date.current,
      total_amount: 15.99
    )
    recent_cycle.save!(validate: false)
    recent_cycle.update_column(:due_date, 1.month.ago)

    archived_count = @service.archive_old_cycles

    assert_equal 0, archived_count
    assert_not recent_cycle.reload.archived?
  end

  test "should not archive already archived cycles" do
    # Create old cycle by building and then updating to bypass validation
    old_cycle = @project.billing_cycles.build(
      due_date: Date.current,
      total_amount: 15.99,
      archived: true
    )
    old_cycle.save!(validate: false)
    old_cycle.update_column(:due_date, 8.months.ago)

    archived_count = @service.archive_old_cycles

    assert_equal 0, archived_count
  end

  test "should not archive old unpaid cycles that are not very old" do
    # Create old unpaid cycle by building and then updating to bypass validation
    old_unpaid_cycle = @project.billing_cycles.build(
      due_date: Date.current,
      total_amount: 15.99
    )
    old_unpaid_cycle.save!(validate: false)
    old_unpaid_cycle.update_column(:due_date, 8.months.ago)

    archived_count = @service.archive_old_cycles

    assert_equal 0, archived_count
    assert_not old_unpaid_cycle.reload.archived?
  end

  test "class method should delegate to instance method" do
    # Create old cycle by building and then updating to bypass validation
    old_cycle = @project.billing_cycles.build(
      due_date: Date.current,
      total_amount: 15.99
    )
    old_cycle.save!(validate: false)
    old_cycle.update_column(:due_date, 8.months.ago)

    # Make it fully paid
    old_cycle.payments.create!(
      user: users(:test_user),
      amount: 5.33,
      status: "confirmed",
      confirmation_date: Date.current
    )
    old_cycle.payments.create!(
      user: users(:member_user),
      amount: 5.33,
      status: "confirmed",
      confirmation_date: Date.current
    )
    old_cycle.payments.create!(
      user: users(:other_user),
      amount: 5.33,
      status: "confirmed",
      confirmation_date: Date.current
    )

    archived_count = BillingCycleArchiverService.archive_old_cycles(6)

    assert_equal 1, archived_count
    assert old_cycle.reload.archived?
  end

  test "should handle custom months_old parameter" do
    service = BillingCycleArchiverService.new(3)

    # Create old cycle by building and then updating to bypass validation
    old_cycle = @project.billing_cycles.build(
      due_date: Date.current,
      total_amount: 15.99
    )
    old_cycle.save!(validate: false)
    old_cycle.update_column(:due_date, 4.months.ago)

    # Make it fully paid
    old_cycle.payments.create!(
      user: users(:test_user),
      amount: 5.33,
      status: "confirmed",
      confirmation_date: Date.current
    )
    old_cycle.payments.create!(
      user: users(:member_user),
      amount: 5.33,
      status: "confirmed",
      confirmation_date: Date.current
    )
    old_cycle.payments.create!(
      user: users(:other_user),
      amount: 5.33,
      status: "confirmed",
      confirmation_date: Date.current
    )

    archived_count = service.archive_old_cycles

    assert_equal 1, archived_count
    assert old_cycle.reload.archived?
  end
end
