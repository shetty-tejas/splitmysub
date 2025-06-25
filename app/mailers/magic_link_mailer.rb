class MagicLinkMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.magic_link_mailer.send_magic_link.subject
  #
  default from: "noreply@splitmysub.com"

  def send_magic_link(user, magic_link)
    @user = user
    @magic_link = magic_link
    @magic_link_url = verify_magic_link_url(token: @magic_link.token)
    @expires_in_minutes = (@magic_link.expires_at - Time.current) / 1.minute

    mail(
      to: @user.email_address,
      subject: "Your SplitMySub Magic Link - Sign in securely"
    )
  end
end
