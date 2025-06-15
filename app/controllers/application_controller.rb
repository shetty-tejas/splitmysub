class ApplicationController < ActionController::Base
  include Authentication
  include Authorization

  # CSRF Protection
  protect_from_forgery with: :exception

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  inertia_share flash: -> { flash.to_hash }
  inertia_share do
    {
      user: Current.user
    } if authenticated?
  end

  wrap_parameters false # Disable default wrapping of parameters in JSON requests (Helpful with Inertia js)

  # Global exception handling
  rescue_from StandardError, with: :handle_standard_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from ActionController::UnpermittedParameters, with: :handle_unpermitted_parameters

  # Handle rate limiting
  rescue_from Rack::Attack::Throttle, with: :handle_rate_limit_exceeded

  private

  def handle_standard_error(exception)
    # Notify error notification service
    ErrorNotificationService.notify_critical_error(exception, {
      controller: self.class.name,
      action: action_name,
      params: params.to_unsafe_h.except("password", "password_confirmation"),
      user_id: Current.user&.id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    })

    respond_to do |format|
      format.html do
        if Rails.env.development?
          raise exception # Let Rails handle it in development
        else
          render file: Rails.root.join("public", "500.html"), status: :internal_server_error, layout: false
        end
      end
      format.json do
        render json: {
          error: "Internal server error",
          message: "Something went wrong. Please try again later."
        }, status: :internal_server_error
      end
    end
  end

  def handle_not_found(exception)
    Rails.logger.warn "Record not found: #{exception.message}"

    respond_to do |format|
      format.html do
        render file: Rails.root.join("public", "404.html"), status: :not_found, layout: false
      end
      format.json do
        render json: {
          error: "Not found",
          message: "The requested resource was not found."
        }, status: :not_found
      end
    end
  end

  def handle_parameter_missing(exception)
    Rails.logger.warn "Parameter missing: #{exception.message}"

    respond_to do |format|
      format.html do
        redirect_back(
          fallback_location: root_path,
          alert: "Required information is missing. Please try again."
        )
      end
      format.json do
        render json: {
          error: "Parameter missing",
          message: "Required parameter is missing: #{exception.param}"
        }, status: :bad_request
      end
    end
  end

  def handle_unpermitted_parameters(exception)
    Rails.logger.warn "Unpermitted parameters: #{exception.message}"

    respond_to do |format|
      format.html do
        redirect_back(
          fallback_location: root_path,
          alert: "Invalid data submitted. Please try again."
        )
      end
      format.json do
        render json: {
          error: "Invalid parameters",
          message: "Some parameters are not allowed."
        }, status: :bad_request
      end
    end
  end

  def handle_rate_limit_exceeded(exception)
    Rails.logger.warn "Rate limit exceeded for IP #{request.ip} on #{request.path}"

    respond_to do |format|
      format.html do
        redirect_back(
          fallback_location: root_path,
          alert: "Too many requests. Please wait a moment before trying again."
        )
      end
      format.json do
        render json: {
          error: "Rate limit exceeded",
          message: "Too many requests. Please try again later."
        }, status: :too_many_requests
      end
    end
  end
end
