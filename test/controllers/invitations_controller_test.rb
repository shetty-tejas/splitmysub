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
          email: "unique_test_user@example.com",
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    invitation = Invitation.last
    assert_equal "unique_test_user@example.com", invitation.email
    assert_equal "member", invitation.role
    assert_equal @user, invitation.invited_by
    assert_equal @project, invitation.project

    # Check JSON response
    json_response = JSON.parse(response.body)
    assert json_response["invitation"]["token"].present?
    assert_equal "unique_test_user@example.com", json_response["invitation"]["email"]
  end

  test "should not create invitation with invalid email" do
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "invalid@local",
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_content
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

  test "should not create duplicate invitation" do
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @invitation.email,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_content
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

  test "should not allow inviting project owner" do
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: @project.user.email_address,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_content
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

      test "should not allow inviting existing member" do
    member_user = users(:member_user)

    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: member_user.email_address,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_content
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

  test "should create invitation with null email for link-only invitations" do
    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: nil,
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["invitation"]["token"].present?
    assert_nil json_response["invitation"]["email"]

    invitation = Invitation.last
    assert_nil invitation.email
    assert_equal "member", invitation.role
    assert_equal @user, invitation.invited_by
    assert_equal @project, invitation.project
  end

      test "should update invitation with email address" do
    @invitation.update!(email: nil) # Start with no email

    patch project_invitation_path(@project, @invitation), params: {
      invitation: { email: "newemail@example.com" }
    }, headers: { "Accept" => "application/json" }

    assert_response :success
    @invitation.reload
    assert_equal "newemail@example.com", @invitation.email

    json_response = JSON.parse(response.body)
    assert_equal "Invitation updated successfully", json_response["message"]
    assert_equal @invitation.id, json_response["invitation"]["id"]
  end

  test "should not update invitation with invalid email" do
    patch project_invitation_path(@project, @invitation), params: {
      invitation: { email: "invalid-email" }
    }, headers: { "Accept" => "application/json" }

    assert_response :unprocessable_content
    json_response = JSON.parse(response.body)
    assert_includes json_response["errors"], "Email must be a valid email address with a proper domain"
  end

    test "should send email for invitation with email address" do
    @invitation.update!(email: "unique_test@example.com")

    assert_enqueued_emails 1 do
      post send_email_project_invitation_path(@project, @invitation),
           headers: { "Accept" => "application/json" }
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Invitation email sent to unique_test@example.com", json_response["message"]
  end

  test "should not send email for invitation without email address" do
    @invitation.update!(email: nil)

    assert_no_enqueued_emails do
      post send_email_project_invitation_path(@project, @invitation),
           headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_content
    json_response = JSON.parse(response.body)
    assert_equal "Cannot send email: no email address provided", json_response["error"]
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

    assert_response :unprocessable_content
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

    assert_response :unprocessable_content
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
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_content
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

  test "should reject invitation with email missing domain" do
    assert_no_difference "Invitation.count" do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "user@local",
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_content
    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

  test "should accept invitation with valid email format" do
    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "valid@example.com",
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["invitation"]["token"].present?
    assert_equal "valid@example.com", json_response["invitation"]["email"]
  end

  # Role validation tests
  test "should accept member role" do
    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "member_role_test@example.com",
          role: "member"
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["invitation"]["token"].present?
    assert_equal "member_role_test@example.com", json_response["invitation"]["email"]
  end

  test "should ignore invalid role parameter and use default member role" do
    assert_difference "Invitation.count", 1 do
      post project_invitations_path(@project), params: {
        invitation: {
          email: "user@example.com",
          role: "invalid"  # This should be ignored
        }
      }, headers: { "Accept" => "application/json" }
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["invitation"]["token"].present?
    assert_equal "user@example.com", json_response["invitation"]["email"]

    # Verify the invitation was created with member role (default)
    invitation = Invitation.last
    assert_equal "member", invitation.role
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
