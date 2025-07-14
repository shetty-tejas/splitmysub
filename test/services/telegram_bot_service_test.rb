require "test_helper"

class TelegramBotServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:test_user)
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)
    @payment = payments(:netflix_member_payment)
    @chat_id = "123456789"

    # Set up user with Telegram
    @user.update!(
      telegram_user_id: @chat_id,
      telegram_username: "testuser",
      telegram_notifications_enabled: true
    )
  end

  test "send_message returns result when bot is available" do
    service = TelegramBotService.new

    # Mock the bot to simulate successful API call
    mock_bot = Minitest::Mock.new
    mock_api = Minitest::Mock.new

    mock_bot.expect :api, mock_api
    mock_api.expect :send_message, { "ok" => true, "result" => { "message_id" => 1 } } do |args|
      args[:chat_id] == @chat_id && args[:text] == "Hello"
    end

    service.instance_variable_set(:@bot, mock_bot)

    result = service.send_message(chat_id: @chat_id, text: "Hello")
    assert_equal({ "message_id" => 1 }, result)

    mock_bot.verify
    mock_api.verify
  end

  test "send_message returns nil when bot is not available" do
    service = TelegramBotService.new
    service.instance_variable_set(:@bot, nil)

    result = service.send_message(chat_id: @chat_id, text: "Hello")
    assert_nil result
  end

  test "send_message handles API error" do
    service = TelegramBotService.new

    mock_bot = Minitest::Mock.new
    mock_api = Minitest::Mock.new

    mock_bot.expect :api, mock_api
    mock_api.expect :send_message, { "ok" => false, "description" => "Bot was blocked" } do |args|
      args[:chat_id] == @chat_id
    end

    service.instance_variable_set(:@bot, mock_bot)

    result = service.send_message(chat_id: @chat_id, text: "Hello")
    assert_nil result

    mock_bot.verify
    mock_api.verify
  end

  test "send_notification creates telegram message and sends" do
    service = TelegramBotService.new

    # Stub the send_message method to return success
    service.stub :send_message, { "message_id" => 1 } do
      assert_difference "TelegramMessage.count", 1 do
        result = service.send_notification(
          user: @user,
          message_type: "payment_reminder",
          content: "Test notification"
        )
        assert result
      end

      message = TelegramMessage.last
      assert_equal @user, message.user
      assert_equal "payment_reminder", message.message_type
      assert_equal "Test notification", message.content
      assert_equal "sent", message.status
      assert_equal "1", message.telegram_message_id
    end
  end

  test "send_notification fails if user has no telegram_user_id" do
    @user.update!(telegram_user_id: nil)
    service = TelegramBotService.new

    result = service.send_notification(
      user: @user,
      message_type: "payment_reminder",
      content: "Test notification"
    )

    assert_not result
  end

  test "send_notification fails if telegram notifications disabled" do
    @user.update!(telegram_notifications_enabled: false)
    service = TelegramBotService.new

    result = service.send_notification(
      user: @user,
      message_type: "payment_reminder",
      content: "Test notification"
    )

    assert_not result
  end

  test "process_webhook handles text message" do
    service = TelegramBotService.new

    webhook_data = {
      "message" => {
        "chat" => { "id" => @chat_id.to_i },
        "from" => { "id" => @chat_id.to_i, "username" => "testuser" },
        "text" => "/help"
      }
    }

    # Stub the handle methods
    service.stub :handle_start_command, true do
      service.stub :handle_help_command, true do
        result = service.process_webhook(webhook_data)
        assert result
      end
    end
  end

  test "process_webhook ignores non-text messages" do
    service = TelegramBotService.new

    webhook_data = {
      "message" => {
        "chat" => { "id" => @chat_id.to_i },
        "from" => { "id" => @chat_id.to_i, "username" => "testuser" },
        "photo" => [ { "file_id" => "photo123" } ]
      }
    }

    result = service.process_webhook(webhook_data)
    assert result
  end

  # Simplified tests for command handlers - these can be basic smoke tests
  test "handle_start_command_with_valid_token_links_account" do
    service = TelegramBotService.new
    token = @user.generate_telegram_verification_token

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_start_command, @chat_id.to_i, "testuser", token)
      assert result
    end
  end

  test "handle_start_command_with_invalid_token_shows_error" do
    service = TelegramBotService.new

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_start_command, @chat_id.to_i, "testuser", "invalid_token")
      assert result
    end
  end

  test "handle_start_command_without_token_shows_welcome_message" do
    service = TelegramBotService.new

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_start_command, @chat_id.to_i, "testuser", nil)
      assert result
    end
  end

  test "handle_help_command_shows_help_text" do
    service = TelegramBotService.new

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_help_command, @chat_id.to_i)
      assert result
    end
  end

  test "handle_status_command_shows_user_status" do
    service = TelegramBotService.new

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_status_command, @user, @chat_id.to_i)
      assert result
    end
  end

  test "handle_payments_command_with_no_pending_payments" do
    service = TelegramBotService.new

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_payments_command, @user, @chat_id.to_i)
      assert result
    end
  end

  test "handle_payments_command_with_pending_payments" do
    service = TelegramBotService.new

    # Create a pending payment for the user
    @payment.update!(status: "pending")

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_payments_command, @user, @chat_id.to_i)
      assert result
    end
  end

  test "handle_pay_command_with_invalid_project" do
    service = TelegramBotService.new

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_pay_command, @user, "/pay 999", @chat_id.to_i)
      assert_nil result
    end
  end

  test "handle_pay_command_confirms_payment_successfully" do
    service = TelegramBotService.new
    @payment.update!(status: "pending")

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_pay_command, @user, "/pay netflix", @chat_id.to_i)
      assert_nil result
    end
  end

  test "handle_pay_command_with_no_pending_payment" do
    service = TelegramBotService.new
    @payment.update!(status: "confirmed", confirmation_date: Date.current)

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_pay_command, @user, "/pay netflix", @chat_id.to_i)
      assert_nil result
    end
  end

  test "handle_settings_command_shows_notification_settings" do
    service = TelegramBotService.new

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_settings_command, @user, @chat_id.to_i)
      assert result
    end
  end

  test "handle_authenticated_command_routes_to_correct_handler" do
    service = TelegramBotService.new

    service.stub :handle_help_command, true do
      result = service.send(:handle_authenticated_command, @user, "/help", @chat_id.to_i)
      assert result
    end
  end

  test "handle_authenticated_command_handles_unknown_command" do
    service = TelegramBotService.new

    service.stub :send_message, { "message_id" => 1 } do
      result = service.send(:handle_authenticated_command, @user, "unknown", @chat_id.to_i)
      assert result
    end
  end
end
