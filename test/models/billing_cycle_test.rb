require "test_helper"

class BillingCycleTest < ActiveSupport::TestCase
  def setup
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)
  end

  test "should belong to project and have many payments" do
    assert_respond_to @billing_cycle, :project
    assert_respond_to @billing_cycle, :payments
    assert_instance_of Project, @billing_cycle.project
  end

  test "should validate presence of due_date and total_amount" do
    billing_cycle = BillingCycle.new
    assert_not billing_cycle.valid?
    assert_includes billing_cycle.errors[:due_date], "can't be blank"
    assert_includes billing_cycle.errors[:total_amount], "can't be blank"
  end

  test "should not allow due_date in the past on create" do
    billing_cycle = BillingCycle.new(
      project: @project,
      due_date: 1.day.ago,
      total_amount: 15.99
    )
    assert_not billing_cycle.valid?
    assert_includes billing_cycle.errors[:due_date], "cannot be in the past"
  end

  test "should calculate payment status correctly" do
    # Clear any existing payments first
    @billing_cycle.payments.destroy_all

    # Test unpaid status
    assert_equal "unpaid", @billing_cycle.payment_status
    assert @billing_cycle.unpaid?
    assert_not @billing_cycle.partially_paid?
    assert_not @billing_cycle.fully_paid?

    # Test partially paid status
    @billing_cycle.payments.create!(
      user: users(:test_user),
      amount: 5.00,
      status: "confirmed",
      confirmation_date: Date.current
    )
    assert_equal "partial", @billing_cycle.payment_status
    assert_not @billing_cycle.unpaid?
    assert @billing_cycle.partially_paid?
    assert_not @billing_cycle.fully_paid?

    # Test fully paid status
    @billing_cycle.payments.create!(
      user: users(:member_user),
      amount: 5.33,
      status: "confirmed",
      confirmation_date: Date.current
    )
    @billing_cycle.payments.create!(
      user: users(:other_user),
      amount: 5.66,
      status: "confirmed",
      confirmation_date: Date.current
    )
    assert_equal "paid", @billing_cycle.payment_status
    assert_not @billing_cycle.unpaid?
    assert_not @billing_cycle.partially_paid?
    assert @billing_cycle.fully_paid?
  end

  test "should calculate days until due correctly" do
    future_cycle = BillingCycle.create!(
      project: @project,
      due_date: 5.days.from_now,
      total_amount: 15.99
    )
    assert_equal 5, future_cycle.days_until_due
  end

  test "should identify overdue cycles" do
    # Create overdue cycle by building and then updating to bypass validation
    overdue_cycle = @project.billing_cycles.build(
      due_date: Date.current,
      total_amount: 15.99
    )
    overdue_cycle.save!(validate: false)
    overdue_cycle.update_column(:due_date, 2.days.ago)

    assert overdue_cycle.overdue?
    assert_not @billing_cycle.overdue?
  end

  test "should identify due soon cycles" do
    due_soon_cycle = BillingCycle.create!(
      project: @project,
      due_date: 3.days.from_now,
      total_amount: 15.99
    )
    assert due_soon_cycle.due_soon?

    # Check that the current billing cycle is also due soon if it's within 7 days
    if @billing_cycle.due_date <= 7.days.from_now
      assert @billing_cycle.due_soon?
    else
      assert_not @billing_cycle.due_soon?
    end
  end

  test "should archive and unarchive cycles" do
    assert_not @billing_cycle.archived?

    @billing_cycle.archive!
    assert @billing_cycle.archived?
    assert_not_nil @billing_cycle.archived_at

    @billing_cycle.unarchive!
    assert_not @billing_cycle.archived?
    assert_nil @billing_cycle.archived_at
  end

  test "should identify archivable cycles" do
    # Create old cycle by building and then updating to bypass validation
    old_cycle = @project.billing_cycles.build(
      due_date: Date.current,
      total_amount: 15.99
    )
    old_cycle.save!(validate: false)
    old_cycle.update_column(:due_date, 8.months.ago)

    assert old_cycle.archivable?
    assert_not @billing_cycle.archivable?
  end

  test "should adjust amount with reason" do
    original_amount = @billing_cycle.total_amount
    new_amount = 25.99
    reason = "Price increase"

    @billing_cycle.adjust_amount!(new_amount, reason)

    assert_equal new_amount, @billing_cycle.total_amount
    assert_equal original_amount, @billing_cycle.original_amount
    assert_equal reason, @billing_cycle.adjustment_reason
    assert_not_nil @billing_cycle.adjusted_at
    assert @billing_cycle.adjusted?
  end

  test "should adjust due date with reason" do
    original_due_date = @billing_cycle.due_date
    new_due_date = 2.weeks.from_now.to_date
    reason = "Extended deadline"

    @billing_cycle.adjust_due_date!(new_due_date, reason)

    assert_equal new_due_date, @billing_cycle.due_date
    assert_equal original_due_date, @billing_cycle.original_due_date
    assert_equal reason, @billing_cycle.adjustment_reason
    assert_not_nil @billing_cycle.adjusted_at
    assert @billing_cycle.adjusted?
  end

  test "should generate adjustment summary" do
    @billing_cycle.adjust_amount!(25.99, "Price increase")
    @billing_cycle.adjust_due_date!(2.weeks.from_now.to_date, "Extended deadline")

    summary = @billing_cycle.adjustment_summary
    assert_includes summary, "Amount:"
    assert_includes summary, "Due Date:"
  end

  test "should scope archived and active cycles correctly" do
    archived_cycle = BillingCycle.create!(
      project: @project,
      due_date: 1.month.from_now,
      total_amount: 15.99,
      archived: true
    )

    active_cycles = BillingCycle.active
    archived_cycles = BillingCycle.archived

    assert_includes active_cycles, @billing_cycle
    assert_not_includes active_cycles, archived_cycle
    assert_includes archived_cycles, archived_cycle
    assert_not_includes archived_cycles, @billing_cycle
  end

  test "should scope archivable cycles correctly" do
    # Create old cycle by building and then updating to bypass validation
    old_cycle = @project.billing_cycles.build(
      due_date: Date.current,
      total_amount: 15.99
    )
    old_cycle.save!(validate: false)
    old_cycle.update_column(:due_date, 8.months.ago)

    archivable_cycles = BillingCycle.archivable
    assert_includes archivable_cycles, old_cycle
    assert_not_includes archivable_cycles, @billing_cycle
  end
end
