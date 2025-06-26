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

  test "full_name returns combined first and last name" do
    user = User.new(first_name: "John", last_name: "Doe")
    assert_equal "John Doe", user.full_name
  end

  test "full_name handles empty first name" do
    user = User.new(first_name: "", last_name: "Doe")
    assert_equal "Doe", user.full_name
  end

  test "full_name handles empty last name" do
    user = User.new(first_name: "John", last_name: "")
    assert_equal "John", user.full_name
  end

  test "full_name handles nil values" do
    user = User.new(first_name: nil, last_name: "Doe")
    assert_equal "Doe", user.full_name

    user = User.new(first_name: "John", last_name: nil)
    assert_equal "John", user.full_name
  end

  test "does not respond to name method" do
    user = User.new
    assert_not user.respond_to?(:name), "User should not have a name method to avoid confusion"
  end
end
