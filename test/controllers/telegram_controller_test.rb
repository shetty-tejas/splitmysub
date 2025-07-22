require "test_helper"

class TelegramControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Override TelegramBotService for testing to avoid actual API calls
    @original_process_webhook = TelegramBotService.instance_method(:process_webhook)
    TelegramBotService.define_method(:process_webhook) { |update| nil }
  end

  teardown do
    # Restore original method
    TelegramBotService.define_method(:process_webhook, @original_process_webhook)
  end

  test "webhook endpoint accepts valid telegram update" do
    update = {
      update_id: 123456789,
      message: {
        message_id: 1,
        chat: { id: 123456789 },
        from: { id: 123456789, username: "test_user" },
        date: Time.current.to_i,
        text: "/start"
      }
    }
    
    post "/telegram/webhook", params: update.to_json, headers: { "Content-Type" => "application/json" }
    
    assert_response :ok
    assert_empty response.body
  end

  test "webhook endpoint handles invalid JSON" do
    post "/telegram/webhook", params: "invalid json", headers: { "Content-Type" => "application/json" }
    
    assert_response :bad_request
  end

  test "webhook endpoint handles service errors gracefully" do
    update = {
      update_id: 123456789,
      message: {
        message_id: 1,
        chat: { id: 123456789 },
        text: "/start"
      }
    }

    # Mock service to raise an error
    TelegramBotService.stub :new, -> { raise StandardError.new("Service error") } do
      post "/telegram/webhook", params: update.to_json, headers: { "Content-Type" => "application/json" }
      
      assert_response :internal_server_error
    end
  end
end