Rails.application.configure do
  # Security Headers Configuration
  config.force_ssl = Rails.env.production?

  # Configure secure session settings
  config.session_store :cookie_store,
    key: "_splitsub_session",
    secure: Rails.env.production?,
    httponly: true,
    same_site: :lax,
    expire_after: 24.hours

  # Security headers middleware
  config.middleware.insert_before ActionDispatch::Static, Rack::Deflater

  # Add security headers and rate limiting
  config.middleware.use Rack::Attack if defined?(Rack::Attack)
end

# Security Headers Middleware
class SecurityHeadersMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Security headers
    headers["X-Frame-Options"] = "DENY"
    headers["X-Content-Type-Options"] = "nosniff"
    headers["X-XSS-Protection"] = "1; mode=block"
    headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    headers["X-Permitted-Cross-Domain-Policies"] = "none"

    # HSTS header for HTTPS
    if env["HTTPS"] == "on" || env["HTTP_X_FORWARDED_PROTO"] == "https"
      headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"
    end

    # Remove server information
    headers.delete("Server")
    headers.delete("X-Powered-By")

    [ status, headers, response ]
  end
end

# Add security headers middleware
Rails.application.config.middleware.use SecurityHeadersMiddleware

# Configure secure cookies in production
if Rails.env.production?
  Rails.application.config.session_options = {
    secure: true,
    httponly: true,
    same_site: :strict
  }
end
