Rails.application.configure do
  # Configure SolidErrors to use the Admin::BaseController for authentication
  config.solid_errors.base_controller_class = "Admin::BaseController"

  # Use the primary database for SolidErrors (simpler setup)
  # Remove the separate database configuration for now
  # config.solid_errors.connects_to = { database: { writing: :errors } }

  # Configure email notifications (only if needed)
  # config.solid_errors.send_emails = false
  # config.solid_errors.email_from = "errors@yourdomain.com"
  # config.solid_errors.email_to = "admin@yourdomain.com"

  # Optional: Auto-destroy resolved errors after 30 days
  config.solid_errors.destroy_after = 30.days
end
