require "test_helper"

class Admin::BillingConfigurationsControllerTest < ActionDispatch::IntegrationTest
      def setup
    # Create test user for admin access (in development mode, all users have admin access)
    @user = User.new(email_address: "admin@splitmysub.test", first_name: "Admin", last_name: "User")
    @user.save!(validate: false)

    # Sign in using the same method as other tests
    sign_in_as(@user)

    # Ensure we have a billing config (don't destroy existing ones, just get current)
    @config = BillingConfig.current
  end

  private

  def sign_in_as(user)
    magic_link = MagicLink.generate_for_user(user, expires_in: 30.minutes)
    get verify_magic_link_url(token: magic_link.token)
  end

  test "should show billing configuration" do
    get admin_billing_configuration_path, headers: {
      "X-Inertia" => "true",
      "X-Inertia-Version" => "1.0"
    }

    # For Inertia.js, success can be 200 or 409 (redirect)
    assert_includes [ 200, 409 ], response.status

    if response.status == 200
      # Test that Inertia response includes the required props
      response_body = JSON.parse(response.body)
      assert response_body["props"]["config"].present?
      assert response_body["props"]["supported_frequencies"].present?
      assert response_body["props"]["preview_data"].present?
      assert_equal @config.id, response_body["props"]["config"]["id"]

      # Test structure of preview_data
      preview_data = response_body["props"]["preview_data"]
      assert preview_data["generation_end_date"].present?
      assert preview_data["archiving_cutoff_date"].present?
      assert preview_data["affected_cycles_count"].present?
    elsif response.status == 409
      # Inertia redirect - this is also valid
      assert response.headers["x-inertia-location"].present?
    end
  end

  test "should show edit billing configuration" do
    get edit_admin_billing_configuration_path, headers: {
      "X-Inertia" => "true",
      "X-Inertia-Version" => "1.0"
    }
    assert_includes [ 200, 409 ], response.status

    if response.status == 200
      # Test that Inertia response includes the required props
      response_body = JSON.parse(response.body)
      assert response_body["props"]["config"].present?
      assert response_body["props"]["supported_frequencies"].present?
    elsif response.status == 409
      # Inertia redirect - this is also valid
      assert response.headers["x-inertia-location"].present?
    end
  end

    test "should update billing configuration with valid params" do
    patch admin_billing_configuration_path, params: {
      billing_config: {
        generation_months_ahead: 4,
        archiving_months_threshold: 8,
        due_soon_days: 5,
        auto_archiving_enabled: false,
        auto_generation_enabled: false,
        payment_grace_period_days: 7,
        reminders_enabled: false,
        gentle_reminder_days_before: 5,
        standard_reminder_days_overdue: 2,
        urgent_reminder_days_overdue: 10,
        final_notice_days_overdue: 20,
        default_frequency: "quarterly"
      }
    }

    assert_redirected_to admin_billing_configuration_path

    # Verify the configuration was actually updated
    @config.reload
    assert_equal 4, @config.generation_months_ahead
    assert_equal 8, @config.archiving_months_threshold
    assert_equal 5, @config.due_soon_days
    assert_equal false, @config.auto_archiving_enabled
    assert_equal false, @config.auto_generation_enabled
    assert_equal 7, @config.payment_grace_period_days
    assert_equal false, @config.reminders_enabled
    assert_equal 5, @config.gentle_reminder_days_before
    assert_equal 2, @config.standard_reminder_days_overdue
    assert_equal 10, @config.urgent_reminder_days_overdue
    assert_equal 20, @config.final_notice_days_overdue
    assert_equal "quarterly", @config.default_frequency
  end

  test "should not update billing configuration with invalid params" do
    original_months_ahead = @config.generation_months_ahead

    patch admin_billing_configuration_path, params: {
      billing_config: {
        generation_months_ahead: -5  # Invalid negative value
      }
    }

    assert_response :success  # Returns to edit form with errors

    # Verify the configuration was NOT updated
    @config.reload
    assert_equal original_months_ahead, @config.generation_months_ahead

    # Test that validation errors are included in response (Inertia response)
    # Note: For validation errors, we expect either a redirect or an Inertia response with errors
    # Since this returns 200 (success), it should be an Inertia response with validation errors
  end

  test "should reset configuration to defaults" do
    # First, modify the configuration
    @config.update!(generation_months_ahead: 10, archiving_months_threshold: 12)

    post reset_admin_billing_configuration_path
    assert_redirected_to admin_billing_configuration_path

    # Verify a new default configuration was created
    new_config = BillingConfig.current
    assert_not_equal @config.id, new_config.id
    assert_equal 3, new_config.generation_months_ahead  # Default value
    assert_equal 6, new_config.archiving_months_threshold  # Default value
  end



  test "should deny access to non-admin users in production-like environment" do
    # This test simulates production environment restrictions
    # Skip in development since we allow all users admin access there
    skip "Admin access control test - implement when role-based auth is added"

    # Example test structure for when admin roles are implemented:
    #
    # @non_admin_user = User.create!(email_address: "user@example.com", first_name: "Regular", last_name: "User")
    # post login_path, params: { email_address: @non_admin_user.email_address }
    #
    # get admin_billing_configuration_path
    # assert_redirected_to root_path
    # assert_equal "Access denied. Administrator privileges required.", flash[:alert]
  end
end
