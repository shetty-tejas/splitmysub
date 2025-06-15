require "test_helper"

class PaymentConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user)
    @other_user = users(:other_user)
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)
    @payment = payments(:netflix_member_payment)

    # Sign in the project owner
    sign_in_as(@user)
  end

  private

  def sign_in_as(user)
    magic_link = MagicLink.generate_for_user(user, expires_in: 30.minutes)
    get verify_magic_link_url(token: magic_link.token)
  end

  test "should get index when project owner" do
    get project_payment_confirmations_url(@project)
    assert_response :success
    assert_includes response.body, "payment_confirmations/Index"
  end

  test "should not get index when not project owner" do
    # Create a user with no relationship to the project
    non_member_user = User.create!(
      email_address: "nonmember@example.com",
      first_name: "Non",
      last_name: "Member"
    )
    sign_in_as(non_member_user)
    get project_payment_confirmations_url(@project)
    assert_redirected_to project_url(@project)
    assert_equal "You don't have permission to manage payment confirmations.", flash[:alert]
  end

  test "should get show when project owner" do
    get project_payment_confirmation_url(@project, @payment)
    assert_response :success
    assert_includes response.body, "payment_confirmations/Show"
  end

  test "should not get show when not project owner" do
    # Create a user with no relationship to the project
    non_member_user = User.create!(
      email_address: "nonmember2@example.com",
      first_name: "Non",
      last_name: "Member2"
    )
    sign_in_as(non_member_user)
    get project_payment_confirmation_url(@project, @payment)
    assert_redirected_to project_url(@project)
    assert_equal "You don't have permission to manage payment confirmations.", flash[:alert]
  end

  test "should confirm payment" do
    assert_equal "pending", @payment.status

    patch project_payment_confirmation_url(@project, @payment), params: {
      action_type: "confirm",
      notes: "Payment verified"
    }

    @payment.reload
    assert_equal "confirmed", @payment.status
    assert_equal "Payment verified", @payment.confirmation_notes
    assert_equal @user, @payment.confirmed_by
    assert_not_nil @payment.confirmation_date
    assert_redirected_to project_payment_confirmation_url(@project, @payment)
    assert_equal "Payment confirmed successfully!", flash[:notice]
  end

  test "should reject payment" do
    assert_equal "pending", @payment.status

    patch project_payment_confirmation_url(@project, @payment), params: {
      action_type: "reject",
      notes: "Insufficient evidence"
    }

    @payment.reload
    assert_equal "rejected", @payment.status
    assert_equal "Insufficient evidence", @payment.confirmation_notes
    assert_equal @user, @payment.confirmed_by
    assert_nil @payment.confirmation_date
    assert_redirected_to project_payment_confirmation_url(@project, @payment)
    assert_equal "Payment rejected.", flash[:notice]
  end

  test "should dispute payment" do
    assert_not @payment.disputed?

    patch project_payment_confirmation_url(@project, @payment), params: {
      action_type: "dispute",
      dispute_reason: "Amount doesn't match receipt"
    }

    @payment.reload
    assert @payment.disputed?
    assert_equal "Amount doesn't match receipt", @payment.dispute_reason
    assert_equal @user, @payment.confirmed_by
    assert_redirected_to project_payment_confirmation_url(@project, @payment)
    assert_equal "Payment marked as disputed.", flash[:notice]
  end

  test "should resolve dispute" do
    @payment.update!(disputed: true, dispute_reason: "Test dispute")

    patch project_payment_confirmation_url(@project, @payment), params: {
      action_type: "resolve_dispute"
    }

    @payment.reload
    assert_not @payment.disputed?
    assert_not_nil @payment.dispute_resolved_at
    assert_equal @user, @payment.confirmed_by
    assert_redirected_to project_payment_confirmation_url(@project, @payment)
    assert_equal "Dispute resolved.", flash[:notice]
  end

  test "should add note to payment" do
    original_notes = @payment.confirmation_notes

    post add_note_project_payment_confirmation_url(@project, @payment), params: {
      note: "Additional verification completed"
    }

    @payment.reload
    assert_includes @payment.confirmation_notes, "Additional verification completed"
    assert_includes @payment.confirmation_notes, @user.email_address
    assert_redirected_to project_payment_confirmation_url(@project, @payment)
    assert_equal "Note added successfully.", flash[:notice]
  end

  test "should batch confirm payments" do
    payment2 = Payment.create!(
      user: @other_user,
      billing_cycle: @billing_cycle,
      amount: 8.00,
      status: "pending"
    )

    patch batch_update_project_payment_confirmations_url(@project), params: {
      payment_ids: [ @payment.id, payment2.id ],
      action_type: "confirm",
      notes: "Batch confirmation"
    }

    @payment.reload
    payment2.reload

    assert_equal "confirmed", @payment.status
    assert_equal "confirmed", payment2.status
    assert_equal "Batch confirmation", @payment.confirmation_notes
    assert_equal "Batch confirmation", payment2.confirmation_notes
    assert_redirected_to project_payment_confirmations_url(@project)
    assert_equal "2 payment(s) updated successfully.", flash[:notice]
  end

  test "should batch reject payments" do
    payment2 = Payment.create!(
      user: @other_user,
      billing_cycle: @billing_cycle,
      amount: 8.00,
      status: "pending"
    )

    patch batch_update_project_payment_confirmations_url(@project), params: {
      payment_ids: [ @payment.id, payment2.id ],
      action_type: "reject",
      notes: "Batch rejection"
    }

    @payment.reload
    payment2.reload

    assert_equal "rejected", @payment.status
    assert_equal "rejected", payment2.status
    assert_equal "Batch rejection", @payment.confirmation_notes
    assert_equal "Batch rejection", payment2.confirmation_notes
    assert_redirected_to project_payment_confirmations_url(@project)
    assert_equal "2 payment(s) updated successfully.", flash[:notice]
  end

  test "should handle empty batch update" do
    patch batch_update_project_payment_confirmations_url(@project), params: {
      payment_ids: [],
      action_type: "confirm"
    }

    assert_redirected_to project_payment_confirmations_url(@project)
    assert_equal "No payments selected.", flash[:alert]
  end

  test "should filter payments by status" do
    get project_payment_confirmations_url(@project), params: { status: "pending" }
    assert_response :success
  end

  test "should filter payments by disputed status" do
    get project_payment_confirmations_url(@project), params: { disputed: "true" }
    assert_response :success
  end

  test "should search payments" do
    get project_payment_confirmations_url(@project), params: { search: @payment.user.email_address }
    assert_response :success
  end

  test "should sort payments" do
    get project_payment_confirmations_url(@project), params: { sort: "amount_desc" }
    assert_response :success
  end

  test "should handle payment not found" do
    get project_payment_confirmation_url(@project, id: 99999)
    assert_redirected_to project_payment_confirmations_url(@project)
    assert_equal "Payment not found.", flash[:alert]
  end

  test "should handle project not found" do
    get project_payment_confirmations_url(project_id: 99999)
    assert_redirected_to dashboard_url
    assert_equal "Project not found.", flash[:alert]
  end

  test "should allow admin to access payment confirmations" do
    # Clear existing memberships to avoid conflicts
    @project.project_memberships.where(user: @other_user).destroy_all
    # Create an admin membership for other_user
    @project.project_memberships.create!(user: @other_user, role: "admin")
    sign_in_as(@other_user)

    get project_payment_confirmations_url(@project)
    assert_response :success
  end

  test "should not allow regular member to access payment confirmations" do
    # Clear existing memberships to avoid conflicts
    @project.project_memberships.where(user: @other_user).destroy_all
    # Create a regular membership for other_user
    @project.project_memberships.create!(user: @other_user, role: "member")
    sign_in_as(@other_user)

    get project_payment_confirmations_url(@project)
    assert_redirected_to project_url(@project)
    assert_equal "You don't have permission to manage payment confirmations.", flash[:alert]
  end
end
