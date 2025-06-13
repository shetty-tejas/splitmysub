require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user)
    @project = projects(:netflix)
    @invitation = Invitation.new(
      email: "newuser@example.com",
      project: @project,
      invited_by: @user,
      role: "member"
    )
  end

  test "should be valid with valid attributes" do
    assert @invitation.valid?
  end

  test "should require email" do
    @invitation.email = nil
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:email], "can't be blank"
  end

  test "should require valid email format" do
    @invitation.email = "invalid-email"
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:email], "must be a valid email address with a proper domain"
  end

  test "should reject email without proper domain" do
    @invitation.email = "user@local"
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:email], "must be a valid email address with a proper domain"
  end

  test "should accept valid email with proper domain" do
    @invitation.email = "user@example.com"
    assert @invitation.valid?
  end

  test "should require project" do
    @invitation.project = nil
    assert_not @invitation.valid?
  end

  test "should require invited_by user" do
    @invitation.invited_by = nil
    assert_not @invitation.valid?
  end

  test "should require role" do
    @invitation.role = nil
    assert_not @invitation.valid?
  end

  test "should only allow valid roles" do
    @invitation.role = "invalid"
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:role], "invalid is not a valid role"
  end

  test "should allow member role" do
    @invitation.role = "member"
    assert @invitation.valid?
  end

  test "should allow admin role" do
    @invitation.role = "admin"
    assert @invitation.valid?
  end

  test "should generate token on creation" do
    @invitation.save!
    assert_not_nil @invitation.token
    assert @invitation.token.length > 20
  end

  test "should set expiration on creation" do
    @invitation.save!
    assert_not_nil @invitation.expires_at
    assert @invitation.expires_at > Time.current
    assert @invitation.expires_at < 8.days.from_now
  end

  test "should default to pending status" do
    @invitation.save!
    assert_equal "pending", @invitation.status
  end

  test "should not allow duplicate email for same project" do
    @invitation.save!
    duplicate = Invitation.new(
      email: @invitation.email,
      project: @project,
      invited_by: @user,
      role: "member"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been invited to this project"
  end

  test "should not allow inviting project owner" do
    @invitation.email = @project.user.email_address
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:email], "cannot invite the project owner"
  end

  test "should not allow inviting existing member" do
    # member_user is already a member of netflix project via fixtures
    member_user = users(:member_user)
    @invitation.email = member_user.email_address
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:email], "is already a member of this project"
  end

  test "expired? should return true when past expiration date" do
    @invitation.save!
    @invitation.update_columns(expires_at: 1.day.ago)
    assert @invitation.expired?
  end

  test "expired? should return true when status is expired" do
    @invitation.save!
    @invitation.update_columns(status: "expired")
    assert @invitation.expired?
  end

  test "expired? should return false when not expired" do
    @invitation.expires_at = 1.day.from_now
    @invitation.status = "pending"
    assert_not @invitation.expired?
  end

  test "active? should return true for pending non-expired invitation" do
    @invitation.status = "pending"
    @invitation.expires_at = 1.day.from_now
    assert @invitation.active?
  end

  test "active? should return false for expired invitation" do
    @invitation.save!
    @invitation.update_columns(status: "pending", expires_at: 1.day.ago)
    assert_not @invitation.active?
  end

  test "active? should return false for accepted invitation" do
    @invitation.status = "accepted"
    @invitation.expires_at = 1.day.from_now
    assert_not @invitation.active?
  end

  test "can_accept? should return true for active invitation" do
    @invitation.status = "pending"
    @invitation.expires_at = 1.day.from_now
    assert @invitation.can_accept?
  end

  test "can_accept? should return false for expired invitation" do
    @invitation.save!
    @invitation.update_columns(status: "pending", expires_at: 1.day.ago)
    assert_not @invitation.can_accept?
  end

  test "accept! should create project membership" do
    @invitation.save!
    new_user = User.create!(
      email_address: @invitation.email,
      first_name: "Test",
      last_name: "User"
    )

    assert_difference "@project.project_memberships.count", 1 do
      @invitation.accept!(new_user)
    end

    membership = @project.project_memberships.find_by(user: new_user)
    assert_not_nil membership
    assert_equal @invitation.role, membership.role
  end

  test "accept! should update status to accepted and expire token" do
    @invitation.save!
    new_user = User.create!(
      email_address: @invitation.email,
      first_name: "Test",
      last_name: "User"
    )

    @invitation.accept!(new_user)
    @invitation.reload

    assert_equal "accepted", @invitation.status
    assert @invitation.expires_at <= Time.current
  end

  test "accept! should return true on success" do
    @invitation.save!
    new_user = User.create!(
      email_address: @invitation.email,
      first_name: "Test",
      last_name: "User"
    )

    result = @invitation.accept!(new_user)
    assert result
  end

  test "accept! should return false for expired invitation" do
    @invitation.save!
    @invitation.update_columns(expires_at: 1.day.ago)
    new_user = User.create!(
      email_address: @invitation.email,
      first_name: "Test",
      last_name: "User"
    )

    result = @invitation.accept!(new_user)
    assert_not result
  end

  test "decline! should update status to declined and expire token" do
    @invitation.save!

    result = @invitation.decline!
    @invitation.reload

    assert result
    assert_equal "declined", @invitation.status
    assert @invitation.expires_at <= Time.current
  end

  test "decline! should return false for expired invitation" do
    @invitation.save!
    @invitation.update_columns(expires_at: 1.day.ago)

    result = @invitation.decline!
    assert_not result
  end

  test "expire! should update status to expired" do
    @invitation.save!

    @invitation.expire!
    @invitation.reload

    assert_equal "expired", @invitation.status
  end

  test "expire! should not update non-pending invitations" do
    @invitation.status = "accepted"
    @invitation.save!

    @invitation.expire!
    @invitation.reload

    assert_equal "accepted", @invitation.status
  end

  test "expire_old_invitations! should expire old pending invitations" do
    old_invitation = Invitation.create!(
      email: "old_expire_test@example.com",
      project: @project,
      invited_by: @user,
      role: "member"
    )
    old_invitation.update_columns(expires_at: 1.day.ago)

    recent_invitation = Invitation.create!(
      email: "recent_expire_test@example.com",
      project: @project,
      invited_by: @user,
      role: "member"
    )

    Invitation.expire_old_invitations!

    old_invitation.reload
    recent_invitation.reload

    assert_equal "expired", old_invitation.status
    assert_equal "pending", recent_invitation.status
  end

  test "scopes should work correctly" do
    pending_invitation = Invitation.create!(
      email: "pending_scope@example.com",
      project: @project,
      invited_by: @user,
      role: "member"
    )

    accepted_invitation = Invitation.create!(
      email: "accepted_scope@example.com",
      project: @project,
      invited_by: @user,
      role: "member"
    )
    accepted_invitation.update_columns(status: "accepted", expires_at: Time.current)

    declined_invitation = Invitation.create!(
      email: "declined_scope@example.com",
      project: @project,
      invited_by: @user,
      role: "member"
    )
    declined_invitation.update_columns(status: "declined", expires_at: Time.current)

    expired_invitation = Invitation.create!(
      email: "expired_scope@example.com",
      project: @project,
      invited_by: @user,
      role: "member"
    )
    expired_invitation.update_columns(status: "expired")

    assert_includes Invitation.pending, pending_invitation
    assert_includes Invitation.accepted, accepted_invitation
    assert_includes Invitation.declined, declined_invitation
    assert_includes Invitation.expired, expired_invitation
    assert_includes Invitation.active, pending_invitation
  end
end
