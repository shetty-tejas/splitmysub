class Admin::BaseController < ApplicationController
  before_action :require_authentication
  before_action :require_admin_access

  private

  def require_admin_access
    return true if Rails.env.development?

    # Ensure ADMIN_PASSWORD is configured in non-development environments
    if ENV["ADMIN_PASSWORD"].blank?
      raise "ADMIN_PASSWORD environment variable must be set for admin access in #{Rails.env} environment"
    end

    authenticate_or_request_with_http_basic("Admin Area") do |username, password|
      username == "superadmin" && password == ENV["ADMIN_PASSWORD"]
    end
  end

  def admin_layout
    "admin"
  end
end
