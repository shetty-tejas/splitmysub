require "test_helper"

class BillingCycleArchiverJobTest < ActiveJob::TestCase
  test "should archive old cycles when performed" do
    project = projects(:netflix)

    # Create old cycle by building and then updating to bypass validation
    old_cycle = project.billing_cycles.build(
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

    archived_count = BillingCycleArchiverJob.perform_now(6)

    assert_equal 1, archived_count
    assert old_cycle.reload.archived?
  end

  test "should be queued on default queue" do
    assert_enqueued_with(job: BillingCycleArchiverJob, queue: "default") do
      BillingCycleArchiverJob.perform_later(6)
    end
  end

  test "should handle custom months_old parameter" do
    project = projects(:netflix)

    # Create old cycle by building and then updating to bypass validation
    old_cycle = project.billing_cycles.build(
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

    assert_not old_cycle.archived?

    archived_count = BillingCycleArchiverJob.perform_now(3)

    assert_equal 1, archived_count
    assert old_cycle.reload.archived?
  end

  test "should handle errors gracefully" do
    # This test ensures the job doesn't crash on errors
    assert_nothing_raised do
      BillingCycleArchiverJob.perform_now(6)
    end
  end
end
