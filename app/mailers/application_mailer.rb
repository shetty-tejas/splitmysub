class ApplicationMailer < ActionMailer::Base
  # Using verified domain splitmysubscription.xyz until splitmysub.com is verified
  # TODO: Change to "noreply@splitmysub.com" once domain is verified in Resend
  default from: "noreply@splitmysubscription.xyz"
  layout "mailer"
end
