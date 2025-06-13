require "test_helper"

class UnsubscribeControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:test_user)
    @project = projects(:netflix)
    @valid_token = generate_unsubscribe_token(@user, @project)
    @invalid_token = "invalid_token"
  end

  test "should show unsubscribe page with valid token" do
    get unsubscribe_path(@valid_token)

    assert_response :success
    assert_select "h2", "Unsubscribe from Reminders"
    assert_select "p", text: /#{@project.name}/
    assert_select "p", text: /#{@user.email_address}/
  end

  test "should show invalid token page with invalid token" do
    get unsubscribe_path(@invalid_token)

    assert_response :success
    assert_select "h3", "Invalid Request"
    assert_select "p", text: /invalid or has expired/
  end

  test "should show invalid token page with malformed token" do
    get unsubscribe_path("malformed_base64")

    assert_response :success
    assert_select "h3", "Invalid Request"
  end

  test "should unsubscribe user with valid token" do
    assert_nil @user.preferences&.dig("unsubscribed_projects")

    post process_unsubscribe_path(@valid_token)

    assert_redirected_to unsubscribe_path(@valid_token)
    assert_match "successfully unsubscribed", flash[:notice]

    @user.reload
    assert_includes @user.preferences["unsubscribed_projects"], @project.id
  end

  test "should not duplicate unsubscribe for already unsubscribed user" do
    # First unsubscribe
    @user.update!(preferences: { "unsubscribed_projects" => [ @project.id ] })

    post process_unsubscribe_path(@valid_token)

    assert_redirected_to unsubscribe_path(@valid_token)
    assert_match "successfully unsubscribed", flash[:notice]

    @user.reload
    # Should still only have one entry
    assert_equal [ @project.id ], @user.preferences["unsubscribed_projects"]
  end

  test "should handle invalid token on unsubscribe" do
    post process_unsubscribe_path(@invalid_token)

    assert_redirected_to unsubscribe_path(@invalid_token)
    assert_match "Invalid unsubscribe token", flash[:alert]
  end

  test "should handle missing user in token" do
    token = generate_unsubscribe_token_with_invalid_user_id

    post process_unsubscribe_path(token)

    assert_redirected_to unsubscribe_path(token)
    assert_match "Invalid unsubscribe request", flash[:alert]
  end

  test "should handle missing project in token" do
    token = generate_unsubscribe_token_with_invalid_project_id

    post process_unsubscribe_path(token)

    assert_redirected_to unsubscribe_path(token)
    assert_match "Invalid unsubscribe request", flash[:alert]
  end

  test "should not require authentication" do
    # Ensure no user is signed in
    get unsubscribe_path(@valid_token)
    assert_response :success

    post process_unsubscribe_path(@valid_token)
    assert_response :redirect
  end

  test "should handle user with no existing preferences" do
    @user.update!(preferences: nil)

    post process_unsubscribe_path(@valid_token)

    assert_redirected_to unsubscribe_path(@valid_token)
    assert_match "successfully unsubscribed", flash[:notice]

    @user.reload
    assert_not_nil @user.preferences
    assert_includes @user.preferences["unsubscribed_projects"], @project.id
  end

  test "should handle user with existing preferences but no unsubscribed_projects" do
    @user.update!(preferences: { "some_other_setting" => true })

    post process_unsubscribe_path(@valid_token)

    assert_redirected_to unsubscribe_path(@valid_token)
    assert_match "successfully unsubscribed", flash[:notice]

    @user.reload
    assert_includes @user.preferences["unsubscribed_projects"], @project.id
    assert @user.preferences["some_other_setting"]
  end

  test "should log unsubscribe action" do
    # Capture log output
    log_output = StringIO.new
    Rails.logger = Logger.new(log_output)

    post process_unsubscribe_path(@valid_token)

    log_content = log_output.string
    assert_match "unsubscribed from reminders", log_content
    assert_match @user.email_address, log_content
    assert_match @project.name, log_content
  end

  private

  def generate_unsubscribe_token(user, project)
    payload = {
      user_id: user.id,
      project_id: project.id,
      timestamp: Time.current.to_i
    }
    Base64.urlsafe_encode64(payload.to_json)
  end

  def generate_unsubscribe_token_with_invalid_user_id
    payload = {
      user_id: 99999,
      project_id: @project.id,
      timestamp: Time.current.to_i
    }
    Base64.urlsafe_encode64(payload.to_json)
  end

  def generate_unsubscribe_token_with_invalid_project_id
    payload = {
      user_id: @user.id,
      project_id: 99999,
      timestamp: Time.current.to_i
    }
    Base64.urlsafe_encode64(payload.to_json)
  end
end
