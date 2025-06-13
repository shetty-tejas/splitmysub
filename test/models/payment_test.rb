require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "should belong to user and billing cycle" do
    payment = payments(:netflix_member_payment)
    assert_respond_to payment, :user
    assert_respond_to payment, :billing_cycle
    assert_instance_of User, payment.user
    assert_instance_of BillingCycle, payment.billing_cycle
  end

  test "should have required attributes" do
    payment = payments(:netflix_member_payment)
    assert_not_nil payment.amount
    assert_not_nil payment.status
  end

  test "should be valid with valid attributes" do
    payment = Payment.new(
      user: users(:test_user),
      billing_cycle: billing_cycles(:netflix_current),
      amount: 8.00,
      status: "pending"
    )
    assert payment.valid?
  end

  test "should enqueue confirmation email job when status changes to confirmed" do
    payment = Payment.create!(
      user: users(:test_user),
      billing_cycle: billing_cycles(:netflix_current),
      amount: 8.00,
      status: "pending"
    )

    assert_enqueued_with(job: PaymentConfirmationJob, args: [ payment.id ]) do
      payment.update!(status: "confirmed", confirmation_date: Date.current)
    end
  end

  test "should not enqueue confirmation email job when status changes to rejected" do
    payment = Payment.create!(
      user: users(:test_user),
      billing_cycle: billing_cycles(:netflix_current),
      amount: 8.00,
      status: "pending"
    )

    assert_no_enqueued_jobs do
      payment.update!(status: "rejected")
    end
  end

  test "should not enqueue confirmation email job when other attributes change" do
    payment = Payment.create!(
      user: users(:test_user),
      billing_cycle: billing_cycles(:netflix_current),
      amount: 8.00,
      status: "confirmed",
      confirmation_date: Date.current
    )

    assert_no_enqueued_jobs do
      payment.update!(amount: 10.00)
    end
  end

  test "confirm! method should update status and confirmation date" do
    payment = Payment.create!(
      user: users(:test_user),
      billing_cycle: billing_cycles(:netflix_current),
      amount: 8.00,
      status: "pending"
    )

    assert_enqueued_with(job: PaymentConfirmationJob) do
      payment.confirm!
    end

    assert payment.confirmed?
    assert_equal Date.current, payment.confirmation_date
  end

  test "reject! method should update status and clear confirmation date" do
    payment = Payment.create!(
      user: users(:test_user),
      billing_cycle: billing_cycles(:netflix_current),
      amount: 8.00,
      status: "confirmed",
      confirmation_date: Date.current
    )

    payment.reject!

    assert payment.rejected?
    assert_nil payment.confirmation_date
  end

  test "should have status helper methods" do
    payment = payments(:netflix_member_payment)

    payment.update!(status: "pending")
    assert payment.pending?
    assert_not payment.confirmed?
    assert_not payment.rejected?

    payment.update!(status: "confirmed", confirmation_date: Date.current)
    assert_not payment.pending?
    assert payment.confirmed?
    assert_not payment.rejected?

    payment.update!(status: "rejected", confirmation_date: nil)
    assert_not payment.pending?
    assert_not payment.confirmed?
    assert payment.rejected?
  end
end
