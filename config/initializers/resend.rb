# Configure Resend for email delivery
if Rails.env.production?
  # Use Resend in production
  Resend.api_key = ENV["RESEND_API_KEY"]
  Rails.application.config.action_mailer.delivery_method = :resend
elsif Rails.env.development? && ENV["USE_RESEND_IN_DEV"]
  # Optional: Use Resend in development when environment variable is set
  Resend.api_key = ENV["RESEND_API_KEY"]
  Rails.application.config.action_mailer.delivery_method = :resend
  Rails.application.config.action_mailer.perform_deliveries = true
end
