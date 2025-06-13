require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "should belong to user" do
    project = projects(:netflix)
    assert_respond_to project, :user
    assert_instance_of User, project.user
  end

  test "should have required attributes" do
    project = projects(:netflix)
    assert_not_nil project.name
    assert_not_nil project.cost
    assert_not_nil project.billing_cycle
    assert_not_nil project.renewal_date
  end

  test "should be valid with valid attributes" do
    project = Project.new(
      name: "Test Service",
      cost: 10.99,
      billing_cycle: "monthly",
      renewal_date: 1.month.from_now,
      payment_instructions: "PayPal: test@example.com",
      reminder_days: 7,
      user: users(:test_user)
    )
    assert project.valid?
  end
end
