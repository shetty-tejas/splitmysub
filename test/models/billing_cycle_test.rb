require "test_helper"

class BillingCycleTest < ActiveSupport::TestCase
  test "should belong to project" do
    billing_cycle = billing_cycles(:netflix_current)
    assert_respond_to billing_cycle, :project
    assert_instance_of Project, billing_cycle.project
  end

  test "should have required attributes" do
    billing_cycle = billing_cycles(:netflix_current)
    assert_not_nil billing_cycle.due_date
    assert_not_nil billing_cycle.total_amount
  end

  test "should be valid with valid attributes" do
    billing_cycle = BillingCycle.new(
      project: projects(:netflix),
      due_date: 1.week.from_now,
      total_amount: 15.99
    )
    assert billing_cycle.valid?
  end
end
