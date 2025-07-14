require "test_helper"

class TelegramNotificationServiceTest < ActiveSupport::TestCase
  setup do
    @service = TelegramNotificationService.new
    @user = users(:test_user)
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)
    @payment = payments(:netflix_member_payment)

    # Set up the user with Telegram
    @user.update!(
      telegram_user_id: "123456789",
      telegram_username: "testuser",
      telegram_notifications_enabled: true
    )

    # Mock the TelegramBotService
    @mock_bot_service = Minitest::Mock.new
    TelegramBotService.stub :new, @mock_bot_service do
      # Tests will define expectations within their scope
    end
  end

  test "send_payment_reminder sends reminder notification" do
    reminder_schedule = reminder_schedules(:netflix_reminder_1)
    
    @mock_bot_service.expect :send_notification, true, [
      user: @user,
      message_type: "payment_reminder",
      content: String
    ]

    TelegramBotService.stub :new, @mock_bot_service do
      result = @service.send_payment_reminder(@billing_cycle.id, reminder_schedule.id, @user.id)
      assert result
    end

    @mock_bot_service.verify
  end

  test "send_payment_reminder includes correct content" do
    reminder_schedule = reminder_schedules(:netflix_reminder_1)
    expected_content = nil
    @mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      expected_content = content
      assert_equal @user, user
      assert_equal "payment_reminder", message_type
      assert_includes content, @project.name
      assert_includes content, @user.format_currency(@project.cost_per_member, @project.currency)
      true
    end

    TelegramBotService.stub :new, @mock_bot_service do
      @service.send_payment_reminder(@billing_cycle.id, reminder_schedule.id, @user.id)
    end

    @mock_bot_service.verify
  end

  test "send_payment_reminder includes urgency for overdue payments" do
    reminder_schedule = reminder_schedules(:netflix_reminder_1)
    @billing_cycle.update!(due_date: 2.days.ago)

    @mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      assert_includes content, "overdue"
      true
    end

    TelegramBotService.stub :new, @mock_bot_service do
      @service.send_payment_reminder(@billing_cycle.id, reminder_schedule.id, @user.id)
    end

    @mock_bot_service.verify
  end

  test "send_payment_reminder includes urgency for due soon payments" do
    reminder_schedule = reminder_schedules(:netflix_reminder_1)
    @billing_cycle.update!(due_date: 1.day.from_now)

    @mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      assert_includes content, "Due in"
      true
    end

    TelegramBotService.stub :new, @mock_bot_service do
      @service.send_payment_reminder(@billing_cycle.id, reminder_schedule.id, @user.id)
    end

    @mock_bot_service.verify
  end

  test "send_billing_cycle_notification sends notification" do
    @mock_bot_service.expect :send_notification, true, [
      user: @user,
      message_type: "billing_cycle_notification",
      content: String
    ]

    TelegramBotService.stub :new, @mock_bot_service do
      result = @service.send_billing_cycle_notification(@billing_cycle.id, @user.id)
      assert result
    end

    @mock_bot_service.verify
  end

  test "send_billing_cycle_notification includes correct content" do
    @mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      assert_equal @user, user
      assert_equal "billing_cycle_notification", message_type
      assert_includes content, "New billing cycle"
      assert_includes content, @project.name
      assert_includes content, @user.format_currency(@project.cost_per_member, @project.currency)
      true
    end

    TelegramBotService.stub :new, @mock_bot_service do
      @service.send_billing_cycle_notification(@billing_cycle.id, @user.id)
    end

    @mock_bot_service.verify
  end

  test "send_payment_confirmation sends confirmation" do
    @mock_bot_service.expect :send_notification, true, [
      user: @user,
      message_type: "payment_confirmation",
      content: String
    ]

    TelegramBotService.stub :new, @mock_bot_service do
      result = @service.send_payment_confirmation(@billing_cycle.id, @user.id)
      assert result
    end

    @mock_bot_service.verify
  end

  test "send_payment_confirmation includes correct content" do
    @payment.update!(status: "confirmed", confirmation_date: Date.current)

    @mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      assert_equal @user, user
      assert_equal "payment_confirmation", message_type
      assert_includes content, "Payment confirmed"
      assert_includes content, @project.name
      true
    end

    TelegramBotService.stub :new, @mock_bot_service do
      @service.send_payment_confirmation(@billing_cycle.id, @user.id)
    end

    @mock_bot_service.verify
  end


  test "methods return false when bot service fails" do
    reminder_schedule = reminder_schedules(:netflix_reminder_1)
    @mock_bot_service.expect :send_notification, false, [ Hash ]

    TelegramBotService.stub :new, @mock_bot_service do
      result = @service.send_payment_reminder(@billing_cycle.id, reminder_schedule.id, @user.id)
      assert_not result
    end

    @mock_bot_service.verify
  end

  test "methods handle exceptions gracefully" do
    reminder_schedule = reminder_schedules(:netflix_reminder_1)
    
    # Stub the service to raise an exception when finding billing cycle
    BillingCycle.stub :find, -> { raise StandardError.new("Not found") } do
      result = @service.send_payment_reminder(@billing_cycle.id, reminder_schedule.id, @user.id)
      assert_not result
    end
  end
end
