require "test_helper"

class UserTelegramTest < ActiveSupport::TestCase
  setup do
    @user = users(:test_user)
  end

  test "telegram_linked? returns true when telegram_user_id is present" do
    @user.update!(telegram_user_id: "123456789")
    assert @user.telegram_linked?
  end

  test "telegram_linked? returns false when telegram_user_id is blank" do
    @user.update!(telegram_user_id: nil)
    assert_not @user.telegram_linked?

    @user.update!(telegram_user_id: "")
    assert_not @user.telegram_linked?
  end

  test "telegram_notifications_enabled? returns correct value" do
    @user.update!(telegram_notifications_enabled: true)
    assert @user.telegram_notifications_enabled?

    @user.update!(telegram_notifications_enabled: false)
    assert_not @user.telegram_notifications_enabled?

    @user.update!(telegram_notifications_enabled: nil)
    assert_not @user.telegram_notifications_enabled?
  end

  test "generate_telegram_verification_token creates and returns token" do
    token = @user.generate_telegram_verification_token

    assert_not_nil token
    assert_equal 32, token.length # SecureRandom.hex(16) produces 32 character string
    assert_equal token, @user.telegram_verification_token
    assert_not_nil @user.telegram_verification_token_expires_at
    assert @user.telegram_verification_token_expires_at > Time.current
    assert @user.telegram_verification_token_expires_at < 31.minutes.from_now
  end

  test "generate_telegram_verification_token updates existing token" do
    original_token = @user.generate_telegram_verification_token
    sleep 0.1 # Ensure different timestamp
    new_token = @user.generate_telegram_verification_token

    assert_not_equal original_token, new_token
    assert_equal new_token, @user.telegram_verification_token
  end

  test "telegram_verification_token_valid? returns true for valid token" do
    @user.generate_telegram_verification_token
    assert @user.telegram_verification_token_valid?
  end

  test "telegram_verification_token_valid? returns false for nil token" do
    @user.update!(telegram_verification_token: nil)
    assert_not @user.telegram_verification_token_valid?
  end

  test "telegram_verification_token_valid? returns false for nil expires_at" do
    @user.update!(
      telegram_verification_token: "valid_token",
      telegram_verification_token_expires_at: nil
    )
    assert_not @user.telegram_verification_token_valid?
  end

  test "telegram_verification_token_valid? returns false for expired token" do
    @user.update!(
      telegram_verification_token: "valid_token",
      telegram_verification_token_expires_at: 1.hour.ago
    )
    assert_not @user.telegram_verification_token_valid?
  end

  test "unlink_telegram_account! clears all telegram fields" do
    @user.update!(
      telegram_user_id: "123456789",
      telegram_username: "testuser",
      telegram_verification_token: "token123",
      telegram_verification_token_expires_at: 1.hour.from_now
    )

    @user.unlink_telegram_account!

    assert_nil @user.telegram_user_id
    assert_nil @user.telegram_username
    assert_nil @user.telegram_verification_token
    assert_nil @user.telegram_verification_token_expires_at
  end

  test "toggle_telegram_notifications! toggles the setting" do
    @user.update!(telegram_notifications_enabled: true)

    @user.toggle_telegram_notifications!
    assert_not @user.telegram_notifications_enabled?

    @user.toggle_telegram_notifications!
    assert @user.telegram_notifications_enabled?
  end

  test "toggle_telegram_notifications! works with nil value" do
    @user.update!(telegram_notifications_enabled: nil)

    @user.toggle_telegram_notifications!
    assert @user.telegram_notifications_enabled?
  end

  test "validates telegram_user_id uniqueness" do
    user1 = users(:test_user)
    user2 = users(:other_user)

    user1.update!(telegram_user_id: "123456789")
    user2.telegram_user_id = "123456789"

    assert_not user2.valid?
    assert_includes user2.errors[:telegram_user_id], "has already been taken"
  end

  test "allows blank telegram_user_id" do
    user1 = users(:test_user)
    user2 = users(:other_user)

    user1.update!(telegram_user_id: nil)
    user2.update!(telegram_user_id: "")

    assert user1.valid?
    assert user2.valid?
  end

  test "validates telegram_verification_token uniqueness" do
    user1 = users(:test_user)
    user2 = users(:other_user)

    user1.update!(telegram_verification_token: "unique_token")
    user2.telegram_verification_token = "unique_token"

    assert_not user2.valid?
    assert_includes user2.errors[:telegram_verification_token], "has already been taken"
  end

  test "allows blank telegram_verification_token" do
    user1 = users(:test_user)
    user2 = users(:other_user)

    user1.update!(telegram_verification_token: nil)
    user2.update!(telegram_verification_token: "")

    assert user1.valid?
    assert user2.valid?
  end

  test "has_many telegram_messages association" do
    assert_respond_to @user, :telegram_messages

    # Create a telegram message
    message = TelegramMessage.create!(
      user: @user,
      message_type: "payment_reminder",
      content: "Test message",
      status: "sent"
    )

    assert_includes @user.telegram_messages, message
  end

  test "telegram_messages are destroyed when user is destroyed" do
    # Create a new user specifically for this test to avoid fixture dependencies
    test_user = User.create!(
      email_address: "destruction_test@example.com",
      first_name: "Test",
      last_name: "User"
    )

    message = TelegramMessage.create!(
      user: test_user,
      message_type: "payment_reminder",
      content: "Test message",
      status: "sent"
    )

    message_id = message.id

    # Ensure the message exists before deletion
    assert TelegramMessage.exists?(message_id)

    # Destroy the user (should cascade to telegram_messages)
    test_user.destroy!

    assert_not TelegramMessage.exists?(message_id)
  end

  test "telegram fields are included in user serialization" do
    @user.update!(
      telegram_user_id: "123456789",
      telegram_username: "testuser",
      telegram_notifications_enabled: true
    )

    serialized = @user.as_json(only: [
      :id, :email_address, :first_name, :last_name, :preferred_currency,
      :telegram_user_id, :telegram_username, :telegram_notifications_enabled
    ])

    assert_equal "123456789", serialized["telegram_user_id"]
    assert_equal "testuser", serialized["telegram_username"]
    assert_equal true, serialized["telegram_notifications_enabled"]
  end
end
