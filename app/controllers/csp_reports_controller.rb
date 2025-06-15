class CspReportsController < ApplicationController
  # Skip CSRF protection for CSP reports (they come from the browser)
  skip_before_action :require_authentication
  protect_from_forgery except: :create

  def create
    # Log CSP violations for security monitoring
    violation_report = params.permit!.to_h

    Rails.logger.warn "CSP Violation Report: #{violation_report.to_json}"

    # In production, you might want to send this to a monitoring service
    if Rails.env.production?
      # Example: Send to monitoring service
      # MonitoringService.report_csp_violation(violation_report)
    end

    head :no_content
  rescue => e
    Rails.logger.error "Error processing CSP violation report: #{e.message}"
    head :bad_request
  end
end
