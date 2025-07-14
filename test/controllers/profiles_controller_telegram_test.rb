require "test_helper"

class ProfilesControllerTelegramTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user)
    sign_in_as(@user)
  end

  test "generate_telegram_token creates token and returns JSON" do
    post profile_telegram_generate_token_path

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response.key?("token")
    assert_not_nil json_response["token"]
    assert_equal 32, json_response["token"].length

    @user.reload
    assert_equal json_response["token"], @user.telegram_verification_token
    assert_not_nil @user.telegram_verification_token_expires_at
    assert @user.telegram_verification_token_expires_at > Time.current
  end

  test "generate_telegram_token overwrites existing token" do
    # Generate first token
    post profile_telegram_generate_token_path
    first_response = JSON.parse(response.body)
    first_token = first_response["token"]

    # Generate second token
    post profile_telegram_generate_token_path
    second_response = JSON.parse(response.body)
    second_token = second_response["token"]

    assert_not_equal first_token, second_token

    @user.reload
    assert_equal second_token, @user.telegram_verification_token
  end

  test "check_telegram_status returns linked false when not linked" do
    get profile_telegram_check_status_path

    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal false, json_response["linked"]
  end

  test "check_telegram_status returns linked true when linked" do
    @user.update!(telegram_user_id: "123456789")

    get profile_telegram_check_status_path

    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal true, json_response["linked"]
  end

  test "unlink_telegram clears telegram fields and redirects" do
    @user.update!(
      telegram_user_id: "123456789",
      telegram_username: "testuser",
      telegram_verification_token: "token123",
      telegram_verification_token_expires_at: 1.hour.from_now
    )

    delete profile_telegram_unlink_path

    assert_redirected_to edit_profile_path

    @user.reload
    assert_nil @user.telegram_user_id
    assert_nil @user.telegram_username
    assert_nil @user.telegram_verification_token
    assert_nil @user.telegram_verification_token_expires_at
  end

  test "toggle_telegram_notifications toggles setting" do
    @user.update!(telegram_notifications_enabled: true)

    patch profile_telegram_toggle_notifications_path

    assert_response :success

    @user.reload
    assert_not @user.telegram_notifications_enabled
  end

  test "toggle_telegram_notifications with nil value enables notifications" do
    @user.update!(telegram_notifications_enabled: nil)

    patch profile_telegram_toggle_notifications_path

    @user.reload
    assert @user.telegram_notifications_enabled
  end

  test "telegram routes require authentication" do
    # Sign out
    delete logout_path

    # Test all telegram routes require auth
    post profile_telegram_generate_token_path
    assert_redirected_to login_path

    get profile_telegram_check_status_path
    assert_redirected_to login_path

    delete profile_telegram_unlink_path
    assert_redirected_to login_path

    patch profile_telegram_toggle_notifications_path
    assert_redirected_to login_path
  end

  test "generate_telegram_token stores token in session" do
    post profile_telegram_generate_token_path

    json_response = JSON.parse(response.body)
    token = json_response["token"]

    # Token should be stored in session for later verification
    assert_equal token, session[:telegram_verification_token]
  end

  test "unlink_telegram clears session token" do
    @user.update!(telegram_user_id: "123456789")
    session[:telegram_verification_token] = "some_token"

    delete profile_telegram_unlink_path

    assert_nil session[:telegram_verification_token]
  end
end
