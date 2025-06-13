require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should have email_address" do
    user = users(:test_user)
    assert_not_nil user.email_address
    assert_equal "test@example.com", user.email_address
  end

  test "should have many sessions" do
    user = users(:test_user)
    assert_respond_to user, :sessions
  end
end
