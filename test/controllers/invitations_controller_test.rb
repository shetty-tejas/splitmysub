require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
    @project = projects(:netflix)
    @invitation = Invitation.create!(
      email: "controller_test@example.com",
      project: @project,
      invited_by: @user,
      role: "member"
    )
    sign_in_as @user
  end

  # Index tests
  test "should get index when authenticated as project owner" do
    get project_invitations_path(@project)
    assert_response :success
  end

  test "should redirect index when not authenticated" do
    sign_out
    get project_invitations_path(@project)
    assert_redirected_to login_path
  end

        test "should not allow access to other user's project invitations" do
    other_user = users(:member_user)
    sign_in_as other_user
    other_project = projects(:spotify) # member_user has no access to spotify

    get project_invitations_path(other_project)
    assert_redirected_to dashboard_path
  end

  # Create tests
  test "should create invitation with valid data" do
    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "newuser@example.com",
          role: "member"
        }
      }
    end

    invitation = Invitation.last
    assert_equal "newuser@example.com", invitation.email
    assert_equal "member", invitation.role
    assert_equal @user, invitation.invited_by
    assert_equal @project, invitation.project
  end

  test "should not create invitation with invalid email" do
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "invalid@local",
          role: "member"
        }
      }
    end
  end

  test "should not create duplicate invitation" do
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @invitation.email,
          role: "member"
        }
      }
    end
  end

  test "should not allow inviting project owner" do
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @project.user.email_address,
          role: "member"
        }
      }
    end
  end

      test "should not allow inviting existing member" do
    member_user = users(:member_user)

    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: member_user.email_address,
          role: "member"
        }
      }
    end
  end

  # Show tests
  test "should show valid invitation" do
    get invitation_path(@invitation.token)
    assert_response :success
  end

  test "should show expired page for expired invitation" do
    @invitation.update_columns(expires_at: 1.day.ago)
    get invitation_path(@invitation.token)
    assert_response :success
    # Should render expired page
  end

  test "should show expired page for accepted invitation" do
    @invitation.update_columns(status: "accepted", expires_at: Time.current)
    get invitation_path(@invitation.token)
    assert_response :success
    # Should render expired page
  end

  test "should show expired page for declined invitation" do
    @invitation.update_columns(status: "declined", expires_at: Time.current)
    get invitation_path(@invitation.token)
    assert_response :success
    # Should render expired page
  end

  test "should redirect for invalid token" do
    get invitation_path("invalid-token")
    assert_redirected_to root_path
  end

  # Accept tests
  test "should accept invitation for new user" do
    sign_out
    post accept_invitation_path(@invitation.token)
    assert_response :success
    # Should render confirmation page for new user
  end

  test "should accept invitation for existing user" do
    existing_user = User.create!(
      email_address: @invitation.email,
      first_name: "Existing",
      last_name: "User"
    )
    sign_out

    assert_difference "@project.project_memberships.count", 1 do
      post accept_invitation_path(@invitation.token)
    end

    @invitation.reload
    assert_equal "accepted", @invitation.status
    assert @invitation.expires_at <= Time.current
  end

  test "should accept invitation for logged in user with matching email" do
    matching_user = User.create!(
      email_address: @invitation.email,
      first_name: "Matching",
      last_name: "User"
    )
    sign_in_as matching_user

    assert_difference "@project.project_memberships.count", 1 do
      post accept_invitation_path(@invitation.token)
    end

    @invitation.reload
    assert_equal "accepted", @invitation.status
    assert_redirected_to project_path(@project)
  end

  test "should not accept expired invitation" do
    @invitation.update_columns(expires_at: 1.day.ago)
    sign_out

    post accept_invitation_path(@invitation.token)
    assert_response :success
    # Should render expired page
  end

  test "should not accept already accepted invitation" do
    @invitation.update_columns(status: "accepted", expires_at: Time.current)
    sign_out

    post accept_invitation_path(@invitation.token)
    assert_response :success
    # Should render expired page
  end

  # Confirm tests (new user creation)
  test "should confirm invitation and create new user" do
    sign_out

    assert_difference "User.count", 1 do
      assert_difference "@project.project_memberships.count", 1 do
        post confirm_invitation_path(@invitation.token), params: {
          first_name: "New",
          last_name: "User"
        }
      end
    end

    new_user = User.find_by(email_address: @invitation.email)
    assert_not_nil new_user
    assert_equal "New", new_user.first_name
    assert_equal "User", new_user.last_name

    @invitation.reload
    assert_equal "accepted", @invitation.status
    assert @invitation.expires_at <= Time.current

    assert_redirected_to project_path(@project)
  end

  test "should not confirm invitation for existing user" do
    existing_user = User.create!(
      email_address: @invitation.email,
      first_name: "Existing",
      last_name: "User"
    )
    sign_out

    assert_no_difference "User.count" do
      post confirm_invitation_path(@invitation.token), params: {
        first_name: "New",
        last_name: "User"
      }
    end

    assert_redirected_to invitation_path(@invitation.token)
  end

  test "should not confirm expired invitation" do
    @invitation.update_columns(expires_at: 1.day.ago)
    sign_out

    assert_no_difference "User.count" do
      post confirm_invitation_path(@invitation.token), params: {
        first_name: "New",
        last_name: "User"
      }
    end

    assert_response :success
    # Should render expired page
  end

  test "should handle user creation errors gracefully" do
    sign_out

    # Test with invalid user data to trigger validation errors
    assert_no_difference "User.count" do
      post confirm_invitation_path(@invitation.token), params: {
        first_name: "", # Empty first name should trigger validation error
        last_name: ""   # Empty last name should trigger validation error
      }
    end

    assert_redirected_to invitation_path(@invitation.token)
  end

  # Decline tests
  test "should decline invitation" do
    sign_out

    post decline_invitation_path(@invitation.token)

    @invitation.reload
    assert_equal "declined", @invitation.status
    assert @invitation.expires_at <= Time.current

    assert_response :success
    # Should render declined thank you page
  end

  test "should not decline expired invitation" do
    @invitation.update_columns(expires_at: 1.day.ago)
    sign_out

    post decline_invitation_path(@invitation.token)

    assert_response :success
    # Should render expired page
  end

  test "should not decline already declined invitation" do
    @invitation.update_columns(status: "declined", expires_at: Time.current)
    sign_out

    post decline_invitation_path(@invitation.token)

    assert_response :success
    # Should render expired page
  end

  test "should not decline already accepted invitation" do
    @invitation.update_columns(status: "accepted", expires_at: Time.current)
    sign_out

    post decline_invitation_path(@invitation.token)

    assert_response :success
    # Should render expired page
  end

  # Destroy tests
  test "should destroy invitation as project owner" do
    assert_difference "Invitation.count", -1 do
      delete project_invitation_path(@project, @invitation)
    end
  end

      test "should not destroy invitation as non-owner" do
    other_user = users(:other_user)
    sign_in_as other_user

    assert_no_difference "Invitation.count" do
      delete project_invitation_path(@project, @invitation)
    end

    assert_redirected_to dashboard_path
  end

  test "should not destroy invitation when not authenticated" do
    sign_out

    assert_no_difference "Invitation.count" do
      delete project_invitation_path(@project, @invitation)
    end

    assert_redirected_to login_path
  end

  # Email validation tests
  test "should reject invitation with invalid email format" do
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "invalid-email",
          role: "member"
        }
      }
    end
  end

  test "should reject invitation with email missing domain" do
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "user@local",
          role: "member"
        }
      }
    end
  end

  test "should accept invitation with valid email format" do
    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "valid@example.com",
          role: "member"
        }
      }
    end
  end

    # Role validation tests
    test "should accept member role" do
    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "member_role_test@example.com",
          role: "member"
        }
      }
    end

    assert_redirected_to project_path(@project)
  end

    test "should accept admin role" do
    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "admin_role_test@example.com",
          role: "admin"
        }
      }
    end

    assert_redirected_to project_path(@project)
  end

  test "should reject invalid role" do
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "user@example.com",
          role: "invalid"
        }
      }
    end
  end

  private

  def sign_in_as(user)
    magic_link = MagicLink.generate_for_user(user, expires_in: 30.minutes)
    get verify_magic_link_url(token: magic_link.token)
  end

  def sign_out
    delete logout_path
  end
end
