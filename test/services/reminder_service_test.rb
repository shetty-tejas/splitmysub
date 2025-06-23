require "test_helper"

class ReminderServiceTest < ActiveJob::TestCase
  def setup
    clear_enqueued_jobs
    @user = users(:test_user)
    # Create a test-specific project to avoid interference from fixtures
    @project = Project.create!(
      name: "Test Project",
      cost: 20.00,
      billing_cycle: "monthly",
      renewal_date: 1.month.from_now,
      reminder_days: 7,
      user: @user,
      slug: "9999999999"
    )
    @service = ReminderService.new
  end

  test "should schedule reminders for billing cycle" do
    # Create a billing cycle due in 14 days
    future_billing_cycle = @project.billing_cycles.create!(
      due_date: 14.days.from_now,
      total_amount: @project.cost
    )

    # Create reminder schedule
    reminder_schedule = @project.reminder_schedules.create!(
      days_before: 14,
      escalation_level: 1
    )

    assert_enqueued_jobs 1, only: ReminderMailerJob do
      @service.schedule_reminders_for_billing_cycle(future_billing_cycle)
    end
  end

  test "should process project reminders for specific project" do
    # Create a billing cycle due in 14 days
    future_billing_cycle = @project.billing_cycles.create!(
      due_date: 14.days.from_now,
      total_amount: @project.cost
    )

    # Create reminder schedule
    @project.reminder_schedules.create!(
      days_before: 14,
      escalation_level: 1
    )

    assert_enqueued_jobs 1, only: ReminderMailerJob do
      @service.process_project_reminders(@project)
    end
  end

  test "should get members to remind excluding unsubscribed users" do
    # Create a billing cycle
    billing_cycle = @project.billing_cycles.create!(
      due_date: 14.days.from_now,
      total_amount: @project.cost
    )

    # Add another member to the project
    member = users(:member_user)
    @project.project_memberships.create!(user: member, role: "member")

    # Unsubscribe the member immediately (skip the initial check)
    member.update!(preferences: { "unsubscribed_projects" => [ @project.id ] })

    # Get members to remind - should exclude unsubscribed member
    members_to_remind = @service.send(:get_members_to_remind, billing_cycle)
    member_emails = members_to_remind.map(&:email_address)

    assert_includes member_emails, @project.user.email_address
    assert_not_includes member_emails, member.email_address
  end

  test "should determine when to send reminder based on date" do
    # Create a billing cycle due in 14 days
    billing_cycle = @project.billing_cycles.create!(
      due_date: 14.days.from_now,
      total_amount: @project.cost
    )

    # Create reminder schedule for 14 days before
    reminder_schedule = @project.reminder_schedules.create!(
      days_before: 14,
      escalation_level: 1
    )

    # Should send reminder today (14 days before due date)
    assert @service.send(:should_send_reminder?, billing_cycle, reminder_schedule)

    # Create reminder schedule for 1 day before (should not send yet since billing cycle is due in 14 days)
    reminder_schedule_future = @project.reminder_schedules.create!(
      days_before: 1,
      escalation_level: 2
    )

    assert_not @service.send(:should_send_reminder?, billing_cycle, reminder_schedule_future)
  end

  test "should not send reminders for fully paid billing cycles" do
    # Create a billing cycle due in 14 days
    billing_cycle = @project.billing_cycles.create!(
      due_date: 14.days.from_now,
      total_amount: @project.cost
    )

    # Create a payment that fully covers the billing cycle
    billing_cycle.payments.create!(
      user: @user,
      amount: @project.cost,  # Pay the full amount, not per member
      status: "confirmed",
      confirmation_date: Date.current
    )

    # Create reminder schedule
    reminder_schedule = @project.reminder_schedules.create!(
      days_before: 14,
      escalation_level: 1
    )

    # Should not enqueue any jobs since billing cycle is fully paid
    assert_no_enqueued_jobs do
      @service.process_project_reminders(@project)
    end
  end

  test "should respect unsubscribe preferences when getting members" do
    # Create a billing cycle
    billing_cycle = @project.billing_cycles.create!(
      due_date: 14.days.from_now,
      total_amount: @project.cost
    )

    # Add another member to the project
    member = users(:member_user)
    @project.project_memberships.create!(user: member, role: "member")

    # Unsubscribe the member
    member.update!(preferences: { "unsubscribed_projects" => [ @project.id ] })

    # Get members to remind - should exclude unsubscribed member
    members_to_remind = @service.send(:get_members_to_remind, billing_cycle)
    member_emails = members_to_remind.map(&:email_address)

    assert_includes member_emails, @project.user.email_address
    assert_not_includes member_emails, member.email_address
  end

  test "class methods should delegate to instance methods" do
    # Test class method delegation
    assert_respond_to ReminderService, :process_all_reminders
    assert_respond_to ReminderService, :process_project_reminders
    assert_respond_to ReminderService, :schedule_reminders_for_billing_cycle
  end
end
