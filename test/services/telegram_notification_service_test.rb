require "test_helper"

class TelegramNotificationServiceTest < ActiveSupport::TestCase
  setup do
    @service = TelegramNotificationService.new
    @user = users(:test_user)
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)
    @payment = payments(:netflix_member_payment)
    @reminder_schedule = reminder_schedules(:netflix_reminder_1)

    # Set up the user with Telegram
    @user.update!(
      telegram_user_id: "123456789",
      telegram_username: "testuser",
      telegram_notifications_enabled: true
    )

    # Set up payment to have confirmation data
    @payment.update!(
      status: "confirmed",
      confirmation_date: Date.current
    )
  end

  test "send_payment_reminder succeeds when user has telegram enabled" do
    # Mock the bot service to return true
    mock_bot_service = Minitest::Mock.new
    mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      user == @user && message_type == "payment_reminder" && content.present?
    end

    @service.instance_variable_set(:@bot_service, mock_bot_service)
    
    result = @service.send_payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert result
    
    mock_bot_service.verify
  end

  test "send_payment_reminder returns false when user has no telegram_user_id" do
    @user.update!(telegram_user_id: nil)
    
    result = @service.send_payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert_not result
  end

  test "send_payment_reminder returns false when telegram notifications disabled" do
    @user.update!(telegram_notifications_enabled: false)
    
    result = @service.send_payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert_not result
  end

  test "send_payment_reminder includes project name in content" do
    expected_content = nil
    mock_bot_service = Minitest::Mock.new
    mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      expected_content = content
      assert_includes content, @project.name
      true
    end

    @service.instance_variable_set(:@bot_service, mock_bot_service)
    @service.send_payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    
    mock_bot_service.verify
  end

  test "send_payment_reminder includes urgency for overdue payments" do
    @billing_cycle.update!(due_date: 2.days.ago)
    
    expected_content = nil
    mock_bot_service = Minitest::Mock.new
    mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      expected_content = content
      assert_includes content, "overdue"
      true
    end

    @service.instance_variable_set(:@bot_service, mock_bot_service)
    @service.send_payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    
    mock_bot_service.verify
  end

  test "send_payment_reminder includes due date for upcoming payments" do
    @billing_cycle.update!(due_date: 1.day.from_now)
    
    expected_content = nil
    mock_bot_service = Minitest::Mock.new
    mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      expected_content = content
      assert_includes content, "Due in"
      true
    end

    @service.instance_variable_set(:@bot_service, mock_bot_service)
    @service.send_payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    
    mock_bot_service.verify
  end

  test "send_billing_cycle_notification succeeds when user has telegram enabled" do
    mock_bot_service = Minitest::Mock.new
    mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      user == @user && message_type == "billing_cycle_notification" && content.present?
    end

    @service.instance_variable_set(:@bot_service, mock_bot_service)
    
    result = @service.send_billing_cycle_notification(@billing_cycle.id, @user.id)
    assert result
    
    mock_bot_service.verify
  end

  test "send_billing_cycle_notification includes correct content" do
    expected_content = nil
    mock_bot_service = Minitest::Mock.new
    mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      expected_content = content
      assert_includes content, "New billing cycle"
      assert_includes content, @project.name
      true
    end

    @service.instance_variable_set(:@bot_service, mock_bot_service)
    @service.send_billing_cycle_notification(@billing_cycle.id, @user.id)
    
    mock_bot_service.verify
  end

  test "send_payment_confirmation succeeds when user has telegram enabled" do
    mock_bot_service = Minitest::Mock.new
    mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      user == @user && message_type == "payment_confirmation" && content.present?
    end

    @service.instance_variable_set(:@bot_service, mock_bot_service)
    
    result = @service.send_payment_confirmation(@billing_cycle.id, @user.id)
    assert result
    
    mock_bot_service.verify
  end

  test "send_payment_confirmation includes correct content" do
    expected_content = nil
    mock_bot_service = Minitest::Mock.new
    mock_bot_service.expect :send_notification, true do |user:, message_type:, content:|
      expected_content = content
      assert_includes content, "Payment confirmed"
      assert_includes content, @project.name
      true
    end

    @service.instance_variable_set(:@bot_service, mock_bot_service)
    @service.send_payment_confirmation(@billing_cycle.id, @user.id)
    
    mock_bot_service.verify
  end

  test "send_account_link_verification always succeeds" do
    token = "test_token_123"
    
    result = @service.send_account_link_verification(@user.id, token)
    assert result
  end

  test "methods return false when bot service fails" do
    mock_bot_service = Minitest::Mock.new
    mock_bot_service.expect :send_notification, false do |user:, message_type:, content:|
      true # Accept any arguments
    end

    @service.instance_variable_set(:@bot_service, mock_bot_service)
    
    result = @service.send_payment_reminder(@billing_cycle.id, @reminder_schedule.id, @user.id)
    assert_not result
    
    mock_bot_service.verify
  end

  test "methods handle exceptions gracefully" do
    # Test with invalid IDs that will cause RecordNotFound
    result = @service.send_payment_reminder(999999, 999999, 999999)
    assert_not result
  end
end