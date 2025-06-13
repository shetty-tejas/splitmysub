require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user)
  end

  test "should get new" do
    get login_url
    assert_response :success
  end



  test "should send magic link for existing user" do
    assert_emails 1 do
      post magic_link_url, params: { email_address: @user.email_address }
    end

    assert_redirected_to login_url
    assert_equal "Magic link sent to your email address. Please check your inbox.", flash[:notice]
  end

  test "should not reveal if email does not exist when sending magic link" do
    assert_emails 0 do
      post magic_link_url, params: { email_address: "nonexistent@example.com" }
    end

    assert_redirected_to login_url
    assert_equal "If an account with that email exists, a magic link has been sent.", flash[:notice]
  end

  test "should verify valid magic link and create session" do
    magic_link = MagicLink.generate_for_user(@user, expires_in: 30.minutes)

    get verify_magic_link_url(token: magic_link.token)

    assert_redirected_to dashboard_url
    assert_equal "Successfully signed in with magic link!", flash[:notice]

    # Verify magic link was used
    magic_link.reload
    assert magic_link.used?
  end

  test "should not verify invalid magic link" do
    get verify_magic_link_url(token: "invalid_token")

    assert_redirected_to login_url
    assert_equal "Invalid or expired magic link. Please request a new one.", flash[:alert]
  end

  test "should not verify expired magic link" do
    magic_link = MagicLink.generate_for_user(@user, expires_in: 30.minutes)
    magic_link.update!(expires_at: 1.hour.ago)

    get verify_magic_link_url(token: magic_link.token)

    assert_redirected_to login_url
    assert_equal "Invalid or expired magic link. Please request a new one.", flash[:alert]
  end

  test "should not verify already used magic link" do
    magic_link = MagicLink.generate_for_user(@user, expires_in: 30.minutes)
    magic_link.use!

    get verify_magic_link_url(token: magic_link.token)

    assert_redirected_to login_url
    assert_equal "Invalid or expired magic link. Please request a new one.", flash[:alert]
  end

    test "should destroy session" do
    # First create a session using magic link
    magic_link = MagicLink.generate_for_user(@user, expires_in: 30.minutes)
    get verify_magic_link_url(token: magic_link.token)

    # Then destroy it
    delete logout_url
    assert_redirected_to root_url
    assert_equal "You have been signed out.", flash[:notice]
  end
end
