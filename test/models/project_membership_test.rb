require "test_helper"

class ProjectMembershipTest < ActiveSupport::TestCase
  test "should belong to user and project" do
    membership = project_memberships(:member_netflix)
    assert_respond_to membership, :user
    assert_respond_to membership, :project
    assert_instance_of User, membership.user
    assert_instance_of Project, membership.project
  end

  test "should have role" do
    membership = project_memberships(:member_netflix)
    assert_not_nil membership.role
    assert_equal "member", membership.role
  end

  test "should be valid with valid attributes" do
    membership = ProjectMembership.new(
      user: users(:member_user),
      project: projects(:adobe),
      role: "member"
    )
    assert membership.valid?, "Expected membership to be valid, but got errors: #{membership.errors.full_messages}"
  end
end
