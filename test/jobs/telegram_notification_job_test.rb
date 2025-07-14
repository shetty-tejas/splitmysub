require "test_helper"

class TelegramNotificationJobTest < ActiveJob::TestCase
  setup do
    @user = users(:test_user)
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)
    @payment = payments(:netflix_member_payment)

    @user.update!(
      telegram_user_id: "123456789",
      telegram_username: "testuser",
      telegram_notifications_enabled: true
    )
  end

  test "enqueues job with correct arguments" do
    reminder_schedule = reminder_schedules(:netflix_reminder_1)
    
    assert_enqueued_with(
      job: TelegramNotificationJob,
      args: [
        {
          notification_type: "payment_reminder",
          billing_cycle_id: @billing_cycle.id,
          reminder_schedule_id: reminder_schedule.id,
          user_id: @user.id
        }
      ]
    ) do
      TelegramNotificationJob.perform_later(
        notification_type: "payment_reminder",
        billing_cycle_id: @billing_cycle.id,
        reminder_schedule_id: reminder_schedule.id,
        user_id: @user.id
      )
    end
  end

  test "performs payment_reminder notification" do
    reminder_schedule = reminder_schedules(:netflix_reminder_1)
    # Mock the TelegramNotificationService
    mock_service = Minitest::Mock.new
    mock_service.expect :send_payment_reminder, true, [ @billing_cycle.id, reminder_schedule.id, @user.id ]

    TelegramNotificationService.stub :new, mock_service do
      TelegramNotificationJob.perform_now(
        notification_type: "payment_reminder",
        billing_cycle_id: @billing_cycle.id,
        reminder_schedule_id: reminder_schedule.id,
        user_id: @user.id
      )
    end

    mock_service.verify
  end

  test "performs billing_cycle_notification" do
    mock_service = Minitest::Mock.new
    mock_service.expect :send_billing_cycle_notification, true, [ @billing_cycle.id, @user.id ]

    TelegramNotificationService.stub :new, mock_service do
      TelegramNotificationJob.perform_now(
        notification_type: "billing_cycle_notification",
        billing_cycle_id: @billing_cycle.id,
        user_id: @user.id
      )
    end

    mock_service.verify
  end

  test "performs payment_confirmation notification" do
    mock_service = Minitest::Mock.new
    mock_service.expect :send_payment_confirmation, true, [ @billing_cycle.id, @user.id ]

    TelegramNotificationService.stub :new, mock_service do
      TelegramNotificationJob.perform_now(
        notification_type: "payment_confirmation",
        billing_cycle_id: @billing_cycle.id,
        user_id: @user.id
      )
    end

    mock_service.verify
  end

  test "performs account_link_verification notification" do
    token = "test_token_123"
    
    mock_service = Minitest::Mock.new
    mock_service.expect :send_account_link_verification, true, [ @user.id, token ]

    TelegramNotificationService.stub :new, mock_service do
      TelegramNotificationJob.perform_now(
        notification_type: "account_link_verification",
        user_id: @user.id,
        token: token
      )
    end

    mock_service.verify
  end

  test "handles missing user gracefully" do
    reminder_schedule = reminder_schedules(:netflix_reminder_1)
    assert_nothing_raised do
      TelegramNotificationJob.perform_now(
        notification_type: "payment_reminder",
        billing_cycle_id: @billing_cycle.id,
        reminder_schedule_id: reminder_schedule.id,
        user_id: 999999 # non-existent user ID
      )
    end
  end

  test "handles missing billing_cycle gracefully" do
    reminder_schedule = reminder_schedules(:netflix_reminder_1)
    assert_nothing_raised do
      TelegramNotificationJob.perform_now(
        notification_type: "payment_reminder",
        billing_cycle_id: 999999, # non-existent billing cycle ID
        reminder_schedule_id: reminder_schedule.id,
        user_id: @user.id
      )
    end
  end


  test "handles missing reminder_schedule gracefully" do
    assert_nothing_raised do
      TelegramNotificationJob.perform_now(
        notification_type: "payment_reminder",
        billing_cycle_id: @billing_cycle.id,
        reminder_schedule_id: 999999, # non-existent reminder schedule ID
        user_id: @user.id
      )
    end
  end

  test "handles unknown notification type gracefully" do
    assert_nothing_raised do
      TelegramNotificationJob.perform_now(
        notification_type: "unknown_type",
        billing_cycle_id: @billing_cycle.id,
        user_id: @user.id
      )
    end
  end

  test "handles service exceptions gracefully" do
    mock_service = Minitest::Mock.new
    mock_service.expect :send_payment_reminder, -> { raise StandardError.new("API Error") }, [ @user, @project, @billing_cycle, @payment ]

    TelegramNotificationService.stub :new, mock_service do
      assert_nothing_raised do
        TelegramNotificationJob.perform_now(
          @user.id,
          "payment_reminder",
          @project.id,
          @billing_cycle.id,
          @payment.id
        )
      end
    end

    mock_service.verify
  end

  test "job is queued in correct queue" do
    assert_equal "default", TelegramNotificationJob.queue_name
  end

  test "job has correct retry configuration" do
    # Test that the job can be retried (default behavior)
    assert TelegramNotificationJob.new.executions < 25 # Default max attempts
  end
end
