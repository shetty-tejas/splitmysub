class Admin::BaseController < ApplicationController
  before_action :require_authentication
  before_action :require_admin_access

  private

  def require_admin_access
    # For now, we'll use a simple check. In production, you'd want proper role-based access
    # This could be based on user roles, specific admin users, or environment-based access
    unless admin_access_allowed?
      redirect_to root_path, alert: "Access denied. Administrator privileges required."
    end
  end

    def admin_access_allowed?
    # Implement your admin access logic here
    # Options:
    # 1. Check for specific admin users by email
    # 2. Check for admin role in user model
    # 3. Environment-based access (development only)
    # 4. Feature flag or configuration-based access

    # For now, allowing access in development/test or for specific email patterns
    Rails.env.development? || Rails.env.test? ||
    current_user&.email_address&.match?(/admin@.*/) ||
    current_user&.email_address&.match?(/@(splitmysub|admin)\./)
  end

  def admin_layout
    "admin"
  end
end
