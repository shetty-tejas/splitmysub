require "test_helper"

class ReminderMailerTest < ActionMailer::TestCase
  def setup
    @user = users(:test_user)
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)
    @reminder_schedule = reminder_schedules(:netflix_reminder_1)
  end

  test "payment_reminder should generate email with correct content" do
    email = ReminderMailer.payment_reminder(
      @billing_cycle.id,
      @reminder_schedule.id,
      @user.id
    )

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @user.email_address ], email.to
    assert_equal "Friendly reminder: #{@project.name} payment due in #{@billing_cycle.days_until_due} days", email.subject
    assert_match @project.name, email.body.to_s
    assert_match @user.email_address, email.body.to_s
    assert_match "unsubscribe", email.body.to_s
  end

  test "payment_reminder should use correct template based on escalation level" do
    # Test gentle reminder (level 1)
    @reminder_schedule.update!(escalation_level: 1)
    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert_match "Friendly reminder", email.subject

    # Test standard reminder (level 2)
    @reminder_schedule.update!(escalation_level: 2)
    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert_match "Reminder:", email.subject

    # Test urgent reminder (level 3)
    @reminder_schedule.update!(escalation_level: 3)
    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert_match "URGENT:", email.subject

    # Test final notice (level 4)
    @reminder_schedule.update!(escalation_level: 4)
    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert_match "FINAL NOTICE:", email.subject

    # Test critical alert (level 5)
    @reminder_schedule.update!(escalation_level: 5)
    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert_match "CRITICAL:", email.subject
  end

  test "payment_reminder should set correct email priority headers" do
    # Test normal priority (levels 1-2)
    @reminder_schedule.update!(escalation_level: 1)
    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert_equal "3", email.header["X-Priority"].to_s
    assert_equal "Normal", email.header["X-MSMail-Priority"].to_s

    # Test high priority (level 3)
    @reminder_schedule.update!(escalation_level: 3)
    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert_equal "2", email.header["X-Priority"].to_s
    assert_equal "High", email.header["X-MSMail-Priority"].to_s

    # Test highest priority (levels 4-5)
    @reminder_schedule.update!(escalation_level: 4)
    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert_equal "1", email.header["X-Priority"].to_s
    assert_equal "High", email.header["X-MSMail-Priority"].to_s
  end

  test "final_notice should generate email with overdue information" do
    # Create an overdue billing cycle
    overdue_billing_cycle = @project.billing_cycles.build(
      due_date: 3.days.ago,
      total_amount: @project.cost
    )
    overdue_billing_cycle.save!(validate: false)

    email = ReminderMailer.final_notice(overdue_billing_cycle.id, @user.id)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @user.email_address ], email.to
    assert_match "FINAL NOTICE", email.subject
    assert_match @project.name, email.subject
    assert_match "OVERDUE", email.body.to_s
    assert_equal "1", email.header["X-Priority"].to_s
  end

  test "payment_confirmation should generate confirmation email" do
    # Create a confirmed payment
    payment = @billing_cycle.payments.create!(
      user: @user,
      amount: @project.cost_per_member,
      status: "confirmed",
      confirmation_date: Date.current
    )

    email = ReminderMailer.payment_confirmation(@billing_cycle.id, @user.id)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @user.email_address ], email.to
    assert_match "Payment confirmed", email.subject
    assert_match @project.name, email.subject
    assert_match "confirmed", email.body.to_s
    assert_match payment.amount.to_s, email.body.to_s
  end

  test "should include payment instructions when present" do
    @project.update!(payment_instructions: "Please pay via bank transfer to account 123456")

    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)

    assert_match "Payment Instructions", email.body.to_s
    assert_match "bank transfer", email.body.to_s
    assert_match "123456", email.body.to_s
  end

  test "should generate unsubscribe token" do
    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)

    # Check that unsubscribe link is present
    assert_match "unsubscribe", email.body.to_s
    assert_match "click here to unsubscribe", email.body.to_s
  end

  test "should handle missing records gracefully" do
    # Test with non-existent billing cycle
    assert_raises(ActiveRecord::RecordNotFound) do
      ReminderMailer.payment_reminder(99999, @reminder_schedule.id, @user.id).deliver_now
    end

    # Test with non-existent reminder schedule
    assert_raises(ActiveRecord::RecordNotFound) do
      ReminderMailer.payment_reminder(@billing_cycle.id, 99999, @user.id).deliver_now
    end

    # Test with non-existent user
    assert_raises(ActiveRecord::RecordNotFound) do
      ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, 99999).deliver_now
    end
  end

  test "should calculate correct amount due" do
    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)

    # The email should contain the cost per member
    expected_amount = @project.cost_per_member
    assert_match expected_amount.to_s, email.body.to_s
  end

  test "should format dates correctly" do
    email = ReminderMailer.payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)

    # Check that due date is formatted properly
    formatted_date = @billing_cycle.due_date.strftime("%B %d, %Y")
    assert_match formatted_date, email.body.to_s
  end

  test "should include project organizer contact in final notice" do
    email = ReminderMailer.final_notice(@billing_cycle.id, @user.id)

    assert_match @project.user.email_address, email.body.to_s
    assert_match "Contact the project organizer", email.body.to_s
  end

  private

  def assert_emails(number, &block)
    original_count = ActionMailer::Base.deliveries.count
    yield
    new_count = ActionMailer::Base.deliveries.count
    assert_equal number, new_count - original_count, "Expected #{number} emails to be sent"
  end
end
