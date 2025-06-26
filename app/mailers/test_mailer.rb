class TestMailer < ApplicationMailer
  default from: "noreply@splitmysubscription.xyz"

  def test_email(to_email)
    delivery_method = Rails.application.config.action_mailer.delivery_method
    @message = case delivery_method
    when :resend
                 "If you're reading this, your Resend API configuration is working!"
    when :smtp
                 "If you're reading this, your SMTP configuration is working!"
    else
                 "If you're reading this, your email configuration is working!"
    end

    @delivery_method = delivery_method.to_s.titleize

    mail(
      to: to_email,
      subject: "SplitMySub Email Test - #{@delivery_method} Configuration Working!"
    )
  end
end
