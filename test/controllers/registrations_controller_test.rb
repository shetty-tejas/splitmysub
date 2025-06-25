require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get signup_url
    assert_response :success
  end

  test "should create user and send magic link with valid turnstile" do
    # Mock the CloudflareTurnstile.validate method to return true
    CloudflareTurnstile.stubs(:validate).returns(true)

    assert_emails 1 do
      post signup_url, params: {
        email_address: "newuser@example.com",
        first_name: "New",
        last_name: "User",
        "cf-turnstile-response": "valid_token"
      }
    end

    assert_redirected_to login_url
    assert_equal "Account created! Please check your email for a magic link to sign in.", flash[:notice]

    # Verify user was created
    user = User.find_by(email_address: "newuser@example.com")
    assert_not_nil user
    assert_equal "New", user.first_name
    assert_equal "User", user.last_name
  end

  test "should not create user without turnstile token" do
    assert_emails 0 do
      post signup_url, params: {
        email_address: "newuser@example.com",
        first_name: "New",
        last_name: "User"
        # No cf-turnstile-response parameter
      }
    end

    assert_redirected_to signup_url

    # Verify user was not created
    user = User.find_by(email_address: "newuser@example.com")
    assert_nil user
  end

  test "should not create user with invalid turnstile token" do
    # Mock the CloudflareTurnstile.validate method to return false
    CloudflareTurnstile.stubs(:validate).returns(false)

    assert_emails 0 do
      post signup_url, params: {
        email_address: "newuser@example.com",
        first_name: "New",
        last_name: "User",
        "cf-turnstile-response": "invalid_token"
      }
    end

    assert_redirected_to signup_url

    # Verify user was not created
    user = User.find_by(email_address: "newuser@example.com")
    assert_nil user
  end

  test "should not create user with invalid data" do
    # Mock the CloudflareTurnstile.validate method to return true
    CloudflareTurnstile.stubs(:validate).returns(true)

    assert_emails 0 do
      post signup_url, params: {
        email_address: "invalid-email",
        first_name: "",
        last_name: "",
        "cf-turnstile-response": "valid_token"
      }
    end

    assert_redirected_to signup_url

    # Verify user was not created
    user = User.find_by(email_address: "invalid-email")
    assert_nil user
  end

  test "should not create user with duplicate email" do
    existing_user = users(:test_user)

    # Mock the CloudflareTurnstile.validate method to return true
    CloudflareTurnstile.stubs(:validate).returns(true)

    assert_emails 0 do
      post signup_url, params: {
        email_address: existing_user.email_address,
        first_name: "Duplicate",
        last_name: "User",
        "cf-turnstile-response": "valid_token"
      }
    end

    assert_redirected_to signup_url
  end
end
