class InvitationMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.invitation_mailer.invite.subject
  #
  default from: "noreply@splitsub.com"

  def invite(invitation)
    @invitation = invitation
    @project = invitation.project
    @invited_by = invitation.invited_by
    @invitation_url = invitation_url(@invitation.token)

    mail(
      to: @invitation.email,
      subject: "You're invited to join #{@project.name} on SplitSub",
      reply_to: @invited_by.email_address
    )
  end
end
