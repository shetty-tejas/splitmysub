require "test_helper"

class InvitationMailerTest < ActionMailer::TestCase
  def setup
    @user = users(:test_user)
    @project = projects(:netflix)
    @invitation = Invitation.create!(
      email: "mailer_test@example.com",
      project: @project,
      invited_by: @user,
      role: "member"
    )
  end

  test "invite email" do
    email = InvitationMailer.invite(@invitation)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @invitation.email ], email.to
    assert_equal "You're invited to join #{@project.name} on SplitSub", email.subject
    assert_match @project.name, email.body.encoded
    assert_match @invitation.invited_by.full_name, email.body.encoded
    assert_match "invitations/", email.body.encoded
  end

  test "invite email contains project details" do
    email = InvitationMailer.invite(@invitation)

    assert_match @project.name, email.body.encoded
    # Description might be nil in fixtures, so check if it exists
    assert_match @project.description, email.body.encoded if @project.description.present?
    assert_match @project.cost.to_s, email.body.encoded
    assert_match @project.billing_cycle.capitalize, email.body.encoded
  end

  test "invite email contains invitation link" do
    email = InvitationMailer.invite(@invitation)

    # Check for invitation URL pattern
    assert_match "http://example.com/invitations/", email.body.encoded
  end

  test "invite email contains inviter information" do
    email = InvitationMailer.invite(@invitation)

    assert_match @invitation.invited_by.full_name, email.body.encoded
    assert_match @invitation.invited_by.email_address, email.body.encoded
  end

  test "invite email contains role information" do
    email = InvitationMailer.invite(@invitation)

    # Role is capitalized in the email template
    assert_match "Member", email.body.encoded
  end

  test "invite email contains expiration information" do
    email = InvitationMailer.invite(@invitation)

    # Check for expiration text in the email
    assert_match "expires on", email.body.encoded
  end

  test "invite email has both html and text parts" do
    email = InvitationMailer.invite(@invitation)

    assert email.multipart?
    assert_equal 2, email.parts.length

    html_part = email.parts.find { |part| part.content_type.include?("text/html") }
    text_part = email.parts.find { |part| part.content_type.include?("text/plain") }

    assert_not_nil html_part
    assert_not_nil text_part

    # Both parts should contain key information
    assert_match @project.name, html_part.body.encoded
    assert_match @project.name, text_part.body.encoded
    assert_match "invitations/", html_part.body.encoded
    assert_match "invitations/", text_part.body.encoded
  end

  test "invite email for admin role" do
    @invitation.update!(role: "admin")
    email = InvitationMailer.invite(@invitation)

    assert_match "Admin", email.body.encoded
  end

  test "invite email for member role" do
    @invitation.update!(role: "member")
    email = InvitationMailer.invite(@invitation)

    assert_match "Member", email.body.encoded
  end

  test "invite email contains payment instructions if present" do
    @project.update!(payment_instructions: "Pay via Venmo @username")
    email = InvitationMailer.invite(@invitation)

    assert_match "Pay via Venmo @username", email.body.encoded
  end

  test "invite email handles missing payment instructions gracefully" do
    @project.update!(payment_instructions: nil)
    email = InvitationMailer.invite(@invitation)

    # Should not crash and should still contain other information
    assert_match @project.name, email.body.encoded
    assert_match "invitations/", email.body.encoded
  end

  test "invite email contains cost per member calculation" do
    email = InvitationMailer.invite(@invitation)

    cost_per_member = @project.cost_per_member
    assert_match cost_per_member.to_s, email.body.encoded
  end

  test "invite email from address is correct" do
    email = InvitationMailer.invite(@invitation)

    assert_equal [ "noreply@splitsub.com" ], email.from
  end

  test "invite email reply-to is inviter's email" do
    email = InvitationMailer.invite(@invitation)

    assert_equal [ @invitation.invited_by.email_address ], email.reply_to
  end
end
