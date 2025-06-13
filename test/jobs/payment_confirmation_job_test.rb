require "test_helper"

class PaymentConfirmationJobTest < ActiveJob::TestCase
  def setup
    @user = users(:test_user)
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)
    @payment = @billing_cycle.payments.create!(
      user: @user,
      amount: @project.cost_per_member,
      status: "confirmed",
      confirmation_date: Date.current
    )
  end

  test "should send confirmation email when performed" do
    assert_emails 1 do
      PaymentConfirmationJob.perform_now(@payment.id)
    end
  end

  test "should not send email if payment is not confirmed" do
    @payment.update!(status: "pending", confirmation_date: nil)

    assert_no_emails do
      PaymentConfirmationJob.perform_now(@payment.id)
    end
  end

  test "should handle missing payment gracefully" do
    assert_raises(ActiveRecord::RecordNotFound) do
      PaymentConfirmationJob.perform_now(99999)
    end
  end

  test "should be queued on default queue" do
    assert_enqueued_with(job: PaymentConfirmationJob, queue: "default") do
      PaymentConfirmationJob.perform_later(@payment.id)
    end
  end

  test "should send email with correct content" do
    PaymentConfirmationJob.perform_now(@payment.id)

    email = ActionMailer::Base.deliveries.last
    assert_equal [ @user.email_address ], email.to
    assert_match "Payment confirmed", email.subject
    assert_match @project.name, email.subject
    assert_match @payment.amount.to_s, email.body.to_s
  end

  test "should handle rejected payments" do
    @payment.update!(status: "rejected", confirmation_date: nil)

    assert_no_emails do
      PaymentConfirmationJob.perform_now(@payment.id)
    end
  end

  test "should handle pending payments" do
    @payment.update!(status: "pending", confirmation_date: nil)

    assert_no_emails do
      PaymentConfirmationJob.perform_now(@payment.id)
    end
  end

  private

  def assert_emails(number, &block)
    original_count = ActionMailer::Base.deliveries.count
    yield
    new_count = ActionMailer::Base.deliveries.count
    assert_equal number, new_count - original_count, "Expected #{number} emails to be sent"
  end

  def assert_no_emails(&block)
    assert_emails(0, &block)
  end
end
