require "test_helper"
require "ostruct"

class AuthorizationTest < ActiveSupport::TestCase
  # Create a test controller to include the Authorization concern
  class TestController < ApplicationController
    include Authorization

    attr_accessor :current_user

    def initialize
      super
    end
  end

  def setup
    @controller = TestController.new
    @user1 = User.create!(
      email_address: "auth-user1-#{Time.current.to_i}@example.com",
      first_name: "Auth",
      last_name: "User1"
    )
    @user2 = User.create!(
      email_address: "auth-user2-#{Time.current.to_i}@example.com",
      first_name: "Auth",
      last_name: "User2"
    )
    @project = Project.create!(
      user: @user1,
      name: "Auth Test Project",
      description: "Test Description",
      cost: 100,
      billing_cycle: "monthly",
      renewal_date: 1.month.from_now,
      reminder_days: 7,
      slug: "8888888888"
    )
    @billing_cycle = BillingCycle.create!(
      project: @project,
      due_date: 1.week.from_now,
      total_amount: 100
    )
    @payment = Payment.create!(
      billing_cycle: @billing_cycle,
      user: @user1,
      amount: 100,
      status: "pending"
    )
  end

  test "authorization concern is included" do
    assert ApplicationController.included_modules.include?(Authorization)
  end

  test "authorization error is defined" do
    assert defined?(Authorization::AuthorizationError)
    assert Authorization::AuthorizationError < StandardError
  end

    test "can? method works for project owner" do
    # Set up session with user
    session = OpenStruct.new(user: @user1)
    Current.session = session

    assert @controller.send(:can?, :read, @project)
    assert @controller.send(:can?, :update, @project)
    assert @controller.send(:can?, :manage, @project)
    assert @controller.send(:can?, :destroy, @project)
  end

    test "can? method denies access for non-owner" do
    session = OpenStruct.new(user: @user2)
    Current.session = session

    assert_not @controller.send(:can?, :update, @project)
    assert_not @controller.send(:can?, :manage, @project)
    assert_not @controller.send(:can?, :destroy, @project)
  end

    test "can? method works for payment owner" do
    session = OpenStruct.new(user: @user1)
    Current.session = session

    assert @controller.send(:can?, :read, @payment)
    assert @controller.send(:can?, :update, @payment)
  end

  test "can? method works for project owner accessing member payment" do
    # Create payment by user2 in user1's project
    membership = @project.project_memberships.create!(user: @user2, role: "member")
    member_payment = Payment.create!(
      billing_cycle: @billing_cycle,
      user: @user2,
      amount: 100,
      status: "pending"
    )

    session = OpenStruct.new(user: @user1)  # Project owner
    Current.session = session

    # Project owner should be able to read member payments
    assert @controller.send(:can?, :read, member_payment)
    assert @controller.send(:can?, :confirm, member_payment)
  end

  test "authorize! raises error when access denied" do
    session = OpenStruct.new(user: @user2)
    Current.session = session

    assert_raises(Authorization::AuthorizationError) do
      @controller.send(:authorize!, :manage, @project)
    end
  end

    test "authorize! passes when access allowed" do
    session = OpenStruct.new(user: @user1)
    Current.session = session

    # Should not raise an error
    assert_nothing_raised do
      @controller.send(:authorize!, :read, @project)
      @controller.send(:authorize!, :manage, @project)
    end
  end

  test "ensure_project_owner! works correctly" do
    session = OpenStruct.new(user: @user1)
    Current.session = session

    # Should not raise for owner
    @controller.send(:ensure_project_owner!, @project)

    session = OpenStruct.new(user: @user2)
    Current.session = session

    # Should raise for non-owner
    assert_raises(Authorization::AuthorizationError) do
      @controller.send(:ensure_project_owner!, @project)
    end
  end

    test "ensure_project_access! works correctly" do
    session = OpenStruct.new(user: @user1)
    Current.session = session

    # Should not raise for owner
    assert_nothing_raised do
      @controller.send(:ensure_project_access!, @project)
    end

    # Add user2 as member
    @project.project_memberships.create!(user: @user2, role: "member")
    session = OpenStruct.new(user: @user2)
    Current.session = session

    # Should not raise for member
    assert_nothing_raised do
      @controller.send(:ensure_project_access!, @project)
    end
  end

  test "current_user_admin? works correctly" do
    # First user should be admin
    first_user = User.first
    if first_user&.id == 1
      session = OpenStruct.new(user: first_user)
      Current.session = session
      assert @controller.send(:current_user_admin?)
    end

    # Other users should not be admin
    session = OpenStruct.new(user: @user2)
    Current.session = session
    assert_not @controller.send(:current_user_admin?) unless @user2.id == 1
  end

  test "shares_project_with? works correctly" do
    session = OpenStruct.new(user: @user1)
    Current.session = session

    # Users don't share projects initially
    assert_not @controller.send(:shares_project_with?, @user2)

    # Add user2 as member
    @project.project_memberships.create!(user: @user2, role: "member")

    # Now they share a project
    assert @controller.send(:shares_project_with?, @user2)
  end

  test "can_access_user? works correctly" do
    session = OpenStruct.new(user: @user1)
    Current.session = session

    # Can access own profile
    assert @controller.send(:can_access_user?, :read, @user1)
    assert @controller.send(:can_access_user?, :update, @user1)

    # Cannot access other user initially
    assert_not @controller.send(:can_access_user?, :read, @user2)

    # Add user2 as member to share project
    @project.project_memberships.create!(user: @user2, role: "member")

    # Now can read other user (they share a project)
    assert @controller.send(:can_access_user?, :read, @user2)

    # But still cannot update other user
    assert_not @controller.send(:can_access_user?, :update, @user2)
  end

  test "can_access_billing_cycle? works correctly" do
    session = OpenStruct.new(user: @user1)
    Current.session = session

    # Project owner can access billing cycle
    assert @controller.send(:can_access_billing_cycle?, :read, @billing_cycle)
    assert @controller.send(:can_access_billing_cycle?, :manage, @billing_cycle)

    session = OpenStruct.new(user: @user2)
    Current.session = session

    # Non-member cannot access
    assert_not @controller.send(:can_access_billing_cycle?, :read, @billing_cycle)

    # Add as member
    @project.project_memberships.create!(user: @user2, role: "member")

    # Member can read but not manage
    assert @controller.send(:can_access_billing_cycle?, :read, @billing_cycle)
    assert_not @controller.send(:can_access_billing_cycle?, :manage, @billing_cycle)
  end
end
