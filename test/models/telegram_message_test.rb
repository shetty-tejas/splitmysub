require "test_helper"

class TelegramMessageTest < ActiveSupport::TestCase
  setup do
    @user = users(:test_user)
    @telegram_message = TelegramMessage.new(
      user: @user,
      message_type: "payment_reminder",
      content: "Test message content",
      status: "pending"
    )
  end

  test "valid telegram message" do
    assert @telegram_message.valid?
  end

  test "requires user" do
    @telegram_message.user = nil
    assert_not @telegram_message.valid?
    assert_includes @telegram_message.errors[:user], "must exist"
  end

  test "requires message_type" do
    @telegram_message.message_type = nil
    assert_not @telegram_message.valid?
    assert_includes @telegram_message.errors[:message_type], "can't be blank"
  end

  test "requires content" do
    @telegram_message.content = nil
    assert_not @telegram_message.valid?
    assert_includes @telegram_message.errors[:content], "can't be blank"
  end

  test "requires status" do
    @telegram_message.status = nil
    assert_not @telegram_message.valid?
    assert_includes @telegram_message.errors[:status], "can't be blank"
  end

  test "validates message_type inclusion" do
    valid_types = %w[payment_reminder billing_cycle_notification payment_confirmation project_invitation]

    valid_types.each do |type|
      @telegram_message.message_type = type
      assert @telegram_message.valid?, "#{type} should be valid"
    end

    @telegram_message.message_type = "invalid_type"
    assert_not @telegram_message.valid?
    assert_includes @telegram_message.errors[:message_type], "is not included in the list"
  end

  test "validates status inclusion" do
    valid_statuses = %w[pending sent delivered failed]

    valid_statuses.each do |status|
      @telegram_message.status = status
      assert @telegram_message.valid?, "#{status} should be valid"
    end

    @telegram_message.status = "invalid_status"
    assert_not @telegram_message.valid?
    assert_includes @telegram_message.errors[:status], "is not included in the list"
  end

  test "telegram_message_id is optional" do
    @telegram_message.telegram_message_id = nil
    assert @telegram_message.valid?
  end

  test "sent_at is optional" do
    @telegram_message.sent_at = nil
    assert @telegram_message.valid?
  end

  test "belongs_to user" do
    assert_equal @user, @telegram_message.user
  end

  test "scopes work correctly" do
    # Create test messages with different statuses
    pending_msg = TelegramMessage.create!(
      user: @user,
      message_type: "payment_reminder",
      content: "Pending message",
      status: "pending"
    )

    sent_msg = TelegramMessage.create!(
      user: @user,
      message_type: "payment_reminder",
      content: "Sent message",
      status: "sent"
    )

    failed_msg = TelegramMessage.create!(
      user: @user,
      message_type: "payment_reminder",
      content: "Failed message",
      status: "failed"
    )

    # Test scopes
    assert_includes TelegramMessage.pending, pending_msg
    assert_not_includes TelegramMessage.pending, sent_msg

    assert_includes TelegramMessage.sent, sent_msg
    assert_not_includes TelegramMessage.sent, pending_msg

    assert_includes TelegramMessage.failed, failed_msg
    assert_not_includes TelegramMessage.failed, sent_msg

    assert_includes TelegramMessage.for_user(@user), pending_msg
    assert_includes TelegramMessage.for_user(@user), sent_msg
    assert_includes TelegramMessage.for_user(@user), failed_msg
  end

  test "recent scope orders by created_at desc" do
    old_msg = TelegramMessage.create!(
      user: @user,
      message_type: "payment_reminder",
      content: "Old message",
      status: "sent",
      created_at: 1.day.ago
    )

    new_msg = TelegramMessage.create!(
      user: @user,
      message_type: "payment_reminder",
      content: "New message",
      status: "sent",
      created_at: 1.hour.ago
    )

    recent_messages = TelegramMessage.recent.limit(2)
    assert_equal new_msg, recent_messages.first
    assert_equal old_msg, recent_messages.last
  end

  test "can save with all fields" do
    @telegram_message.telegram_message_id = "123456"
    @telegram_message.sent_at = Time.current

    assert @telegram_message.save
    assert_equal "123456", @telegram_message.telegram_message_id
    assert_not_nil @telegram_message.sent_at
  end

  test "can save with failed status" do
    @telegram_message.status = "failed"

    assert @telegram_message.save
    assert_equal "failed", @telegram_message.status
  end
end
