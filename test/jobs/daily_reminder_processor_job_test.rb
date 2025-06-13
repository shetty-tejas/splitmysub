require "test_helper"

class DailyReminderProcessorJobTest < ActiveJob::TestCase
  test "should be queued on default queue" do
    assert_enqueued_with(job: DailyReminderProcessorJob, queue: "default") do
      DailyReminderProcessorJob.perform_later
    end
  end
end
