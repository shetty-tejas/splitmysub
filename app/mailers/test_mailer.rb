class TestMailer < ApplicationMailer
  default from: "noreply@splitmysubscription.xyz"

  def test_email(to_email)
    @message = "If you're reading this, your SMTP configuration is working!"
    mail(
      to: to_email,
      subject: "SplitMySub SMTP Test - Configuration Working!"
    )
  end
end
