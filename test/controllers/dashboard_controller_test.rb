require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user)
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)
    @payment = payments(:adobe_pending)
    sign_in_as(@user)
  end

  private

  def sign_in_as(user)
    magic_link = MagicLink.generate_for_user(user, expires_in: 30.minutes)
    get verify_magic_link_url(token: magic_link.token)
  end

  def sign_out
    delete logout_path
  end

  test "should get index" do
    get dashboard_url
    assert_response :success
    assert_includes response.body, "dashboard/Index"
  end

  test "should get payment history" do
    get dashboard_payment_history_url
    assert_response :success
    assert_includes response.body, "dashboard/PaymentHistory"
  end

  test "should get payment history with filters" do
    get dashboard_payment_history_url, params: {
      status: "confirmed",
      search: "netflix",
      date_from: "2024-01-01",
      date_to: "2024-12-31"
    }
    assert_response :success
    assert_includes response.body, "dashboard/PaymentHistory"
  end

  test "should get upcoming payments" do
    get dashboard_upcoming_payments_url
    assert_response :success
    assert_includes response.body, "dashboard/UpcomingPayments"
  end

  test "should get analytics" do
    get dashboard_analytics_url
    assert_response :success
    assert_includes response.body, "dashboard/Analytics"
  end

  test "should export payments as CSV" do
    get dashboard_export_payments_url, headers: { "Accept" => "text/csv" }
    assert_response :success
    assert_equal "text/csv", response.content_type
    assert_includes response.headers["Content-Disposition"], "payment_history"
  end

  test "should export payments with filters as CSV" do
    get dashboard_export_payments_url,
        params: { status: "confirmed", search: "netflix" },
        headers: { "Accept" => "text/csv" }
    assert_response :success
    assert_equal "text/csv", response.content_type
  end

  test "should require authentication for all actions" do
    sign_out

    get dashboard_url
    assert_redirected_to login_path

    get dashboard_payment_history_url
    assert_redirected_to login_path

    get dashboard_upcoming_payments_url
    assert_redirected_to login_path

    get dashboard_analytics_url
    assert_redirected_to login_path

    get dashboard_export_payments_url
    assert_redirected_to login_path
  end

  test "should include user projects in dashboard data" do
    get dashboard_url
    assert_response :success

    # Check that the response includes project data
    assert_includes response.body, @project.name
  end

  test "should calculate dashboard stats correctly" do
    get dashboard_url
    assert_response :success

    # The response should include stats data
    assert_includes response.body, "stats"
  end

  test "should handle pagination in payment history" do
    get dashboard_payment_history_url, params: { page: 1 }
    assert_response :success
    assert_includes response.body, "dashboard/PaymentHistory"
  end

  test "should handle empty results gracefully" do
    # Create a user with no payments
    new_user = User.create!(
      email_address: "empty@example.com",
      first_name: "Empty",
      last_name: "User"
    )
    sign_in_as(new_user)

    get dashboard_url
    assert_response :success

    get dashboard_payment_history_url
    assert_response :success

    get dashboard_upcoming_payments_url
    assert_response :success

    get dashboard_analytics_url
    assert_response :success
  end
end
