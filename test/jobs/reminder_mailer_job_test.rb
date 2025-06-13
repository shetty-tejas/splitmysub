require "test_helper"

class ReminderMailerJobTest < ActiveJob::TestCase
  def setup
    @user = users(:test_user)
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)
    @reminder_schedule = reminder_schedules(:netflix_reminder_1)
  end

  test "should send reminder email when performed" do
    assert_emails 1 do
      ReminderMailerJob.perform_now(
        billing_cycle_id: @billing_cycle.id,
        reminder_schedule_id: @reminder_schedule.id,
        user_id: @user.id
      )
    end
  end

  test "should not send email if billing cycle is fully paid" do
    # Create a payment that fully covers the billing cycle
    @billing_cycle.payments.create!(
      user: @user,
      amount: @project.cost_per_member,
      status: "confirmed",
      confirmation_date: Date.current
    )

    assert_no_emails do
      ReminderMailerJob.perform_now(
        billing_cycle_id: @billing_cycle.id,
        reminder_schedule_id: @reminder_schedule.id,
        user_id: @user.id
      )
    end
  end

  test "should be queued on default queue" do
    assert_enqueued_with(job: ReminderMailerJob, queue: "default") do
      ReminderMailerJob.perform_later(
        billing_cycle_id: @billing_cycle.id,
        reminder_schedule_id: @reminder_schedule.id,
        user_id: @user.id
      )
    end
  end

  test "should handle missing billing cycle gracefully" do
    assert_raises(ActiveRecord::RecordNotFound) do
      ReminderMailerJob.perform_now(
        billing_cycle_id: 99999,
        reminder_schedule_id: @reminder_schedule.id,
        user_id: @user.id
      )
    end
  end

  test "should handle missing reminder schedule gracefully" do
    assert_raises(ActiveRecord::RecordNotFound) do
      ReminderMailerJob.perform_now(
        billing_cycle_id: @billing_cycle.id,
        reminder_schedule_id: 99999,
        user_id: @user.id
      )
    end
  end

  test "should handle missing user gracefully" do
    assert_raises(ActiveRecord::RecordNotFound) do
      ReminderMailerJob.perform_now(
        billing_cycle_id: @billing_cycle.id,
        reminder_schedule_id: @reminder_schedule.id,
        user_id: 99999
      )
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
