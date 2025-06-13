require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get signup_url
    assert_response :success
  end

  test "should create user and send magic link" do
    assert_emails 1 do
      post signup_url, params: {
        email_address: "newuser@example.com",
        first_name: "New",
        last_name: "User"
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

  test "should not create user with invalid data" do
    assert_emails 0 do
      post signup_url, params: {
        email_address: "invalid-email",
        first_name: "",
        last_name: ""
      }
    end

    assert_redirected_to signup_url

    # Verify user was not created
    user = User.find_by(email_address: "invalid-email")
    assert_nil user
  end

  test "should not create user with duplicate email" do
    existing_user = users(:test_user)

    assert_emails 0 do
      post signup_url, params: {
        email_address: existing_user.email_address,
        first_name: "Duplicate",
        last_name: "User"
      }
    end

    assert_redirected_to signup_url
  end
end
