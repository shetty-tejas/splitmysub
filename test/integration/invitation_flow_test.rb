require "test_helper"

class InvitationFlowTest < ActionDispatch::IntegrationTest
  def setup
    @owner = users(:test_user)
    @project = projects(:netflix)
    @invitation_email = "integration_test_user@example.com"
  end

  test "complete invitation flow for new user" do
    # Step 1: Owner creates invitation
    sign_in @owner

    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @invitation_email,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    invitation = Invitation.last
    assert_equal @invitation_email, invitation.email
    assert_equal "pending", invitation.status

    # Step 2: Email is sent
    assert_emails 1 do
      InvitationMailer.invite(invitation).deliver_now
    end

    sign_out

    # Step 3: New user visits invitation link
    get invitation_path(invitation.token)
    assert_response :success

    # Step 4: New user accepts invitation
    post accept_invitation_path(invitation.token)
    assert_response :success
    # Should render confirmation page for new user

    # Step 5: New user provides details and confirms
    assert_difference "User.count", 1 do
      assert_difference "@project.project_memberships.count", 1 do
        post confirm_invitation_path(invitation.token), params: {
          first_name: "New",
          last_name: "User"
        }
      end
    end

    # Verify user was created correctly
    new_user = User.find_by(email_address: @invitation_email)
    assert_not_nil new_user
    assert_equal "New", new_user.first_name
    assert_equal "User", new_user.last_name

    # Verify membership was created
    membership = @project.project_memberships.find_by(user: new_user)
    assert_not_nil membership
    assert_equal "member", membership.role

    # Verify invitation was accepted and expired
    invitation.reload
    assert_equal "accepted", invitation.status
    assert invitation.expires_at <= Time.current

    # Should redirect to project page
    assert_redirected_to project_path(@project)
  end

  test "complete invitation flow for existing user" do
    # Create existing user
    existing_user = User.create!(
      email_address: @invitation_email,
      first_name: "Existing",
      last_name: "User"
    )

    # Step 1: Owner creates invitation
    sign_in @owner

    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @invitation_email,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    invitation = Invitation.last
    sign_out

    # Step 2: Existing user visits invitation link (not logged in)
    get invitation_path(invitation.token)
    assert_response :success

    # Step 3: Existing user accepts invitation
    assert_difference "@project.project_memberships.count", 1 do
      post accept_invitation_path(invitation.token)
    end

    # Verify membership was created
    membership = @project.project_memberships.find_by(user: existing_user)
    assert_not_nil membership
    assert_equal "member", membership.role

    # Verify invitation was accepted and expired
    invitation.reload
    assert_equal "accepted", invitation.status
    assert invitation.expires_at <= Time.current

    # Should redirect to project page
    assert_redirected_to project_path(@project)
  end

  test "complete invitation flow for logged in user with matching email" do
    # Create and sign in user with matching email
    matching_user = User.create!(
      email_address: @invitation_email,
      first_name: "Matching",
      last_name: "User"
    )

    # Step 1: Owner creates invitation
    sign_in @owner

    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @invitation_email,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    invitation = Invitation.last
    sign_out

    # Step 2: User signs in and visits invitation link
    sign_in matching_user
    get invitation_path(invitation.token)
    assert_response :success

    # Step 3: User accepts invitation
    assert_difference "@project.project_memberships.count", 1 do
      post accept_invitation_path(invitation.token)
    end

    # Verify membership was created
    membership = @project.project_memberships.find_by(user: matching_user)
    assert_not_nil membership
    assert_equal "member", membership.role

    # Verify invitation was accepted and expired
    invitation.reload
    assert_equal "accepted", invitation.status
    assert invitation.expires_at <= Time.current

    # Should redirect to project page
    assert_redirected_to project_path(@project)
  end

  test "invitation decline flow" do
    # Step 1: Owner creates invitation
    sign_in @owner

    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @invitation_email,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    invitation = Invitation.last
    sign_out

    # Step 2: User visits invitation link
    get invitation_path(invitation.token)
    assert_response :success

    # Step 3: User declines invitation
    assert_no_difference "@project.project_memberships.count" do
      post decline_invitation_path(invitation.token)
    end

    # Verify invitation was declined and expired
    invitation.reload
    assert_equal "declined", invitation.status
    assert invitation.expires_at <= Time.current

    # Should render declined thank you page
    assert_response :success
  end

  test "expired invitation handling" do
    # Step 1: Owner creates invitation
    sign_in @owner

    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @invitation_email,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    invitation = Invitation.last
    sign_out

    # Step 2: Manually expire the invitation
    invitation.update_columns(expires_at: 1.day.ago)

    # Step 3: User tries to visit expired invitation
    get invitation_path(invitation.token)
    assert_response :success
    # Should render expired page

    # Step 4: User tries to accept expired invitation
    post accept_invitation_path(invitation.token)
    assert_response :success
    # Should render expired page

    # Step 5: User tries to decline expired invitation
    post decline_invitation_path(invitation.token)
    assert_response :success
    # Should render expired page
  end

  test "invalid invitation token handling" do
    get invitation_path("invalid-token")
    assert_redirected_to root_path

    post accept_invitation_path("invalid-token")
    assert_redirected_to root_path

    post decline_invitation_path("invalid-token")
    assert_redirected_to root_path

    post confirm_invitation_path("invalid-token"), params: {
      first_name: "Test",
      last_name: "User"
    }
    assert_redirected_to root_path
  end

  test "duplicate invitation prevention" do
    sign_in @owner

    # Create first invitation
    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @invitation_email,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success

    # Try to create duplicate invitation
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @invitation_email,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_entity
  end

  test "cannot invite project owner" do
    sign_in @owner

    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @owner.email_address,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_entity
  end

    test "cannot invite existing member" do
    # other_user is already a member of netflix project (from fixtures)
    member = users(:other_user)

    sign_in @owner

    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: member.email_address,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_entity
  end

  test "email validation during invitation creation" do
    sign_in @owner

    # Test invalid email format
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "invalid-email",
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end
    assert_response :unprocessable_entity

    # Test email without proper domain
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "user@local",
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end
    assert_response :unprocessable_entity

    # Test valid email
    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "valid@example.com",
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end
    assert_response :success
  end

  test "race condition handling in user creation" do
    sign_in @owner

    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @invitation_email,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    invitation = Invitation.last
    sign_out

    # Accept invitation
    post accept_invitation_path(invitation.token)

    # Simulate race condition by creating user between accept and confirm
    User.create!(
      email_address: @invitation_email,
      first_name: "Race",
      last_name: "Condition"
    )

    # Confirm should handle existing user gracefully
    assert_no_difference "User.count" do
      post confirm_invitation_path(invitation.token), params: {
        first_name: "New",
        last_name: "User"
      }
    end

    # Should return unprocessable entity for existing user
    assert_response :unprocessable_entity
  end

  private

  def sign_in(user)
    magic_link = MagicLink.generate_for_user(user, expires_in: 30.minutes)
    get verify_magic_link_url(token: magic_link.token)
  end

  def sign_out
    delete logout_path
  end
end
