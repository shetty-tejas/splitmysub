require "test_helper"

class ReminderScheduleTest < ActiveSupport::TestCase
  test "should belong to project" do
    reminder = reminder_schedules(:netflix_reminder_1)
    assert_respond_to reminder, :project
    assert_instance_of Project, reminder.project
  end

  test "should have required attributes" do
    reminder = reminder_schedules(:netflix_reminder_1)
    assert_not_nil reminder.days_before
    assert_not_nil reminder.escalation_level
  end

  test "should be valid with valid attributes" do
    reminder = ReminderSchedule.new(
      project: projects(:netflix),
      days_before: 14,
      escalation_level: 3
    )
    assert reminder.valid?, "Expected reminder to be valid, but got errors: #{reminder.errors.full_messages}"
  end
end
