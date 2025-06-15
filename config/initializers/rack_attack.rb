class Rack::Attack
  # Configure cache store for rate limiting
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Allow localhost and private networks in development
  safelist("allow-localhost") do |req|
    Rails.env.development? && [ "127.0.0.1", "::1" ].include?(req.ip)
  end

  # Allow admin users to bypass rate limits
  safelist("allow-admin") do |req|
    # Check if user is admin (you'll need to implement this based on your auth system)
    if req.session && req.session[:user_id]
      user = User.find_by(id: req.session[:user_id])
      user&.id == 1 # First user is admin for now
    end
  end

  # Rate limit magic link requests
  throttle("magic_link_requests/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == "/magic_link" && req.post?
  end

  # Rate limit magic link requests per email
  throttle("magic_link_requests/email", limit: 3, period: 30.minutes) do |req|
    if req.path == "/magic_link" && req.post?
      req.params.dig("email")&.downcase
    end
  end

  # Rate limit login attempts
  throttle("login_attempts/ip", limit: 10, period: 15.minutes) do |req|
    req.ip if req.path == "/login" && req.post?
  end

  # Rate limit file uploads
  throttle("file_uploads/ip", limit: 20, period: 1.hour) do |req|
    req.ip if req.path.include?("/payments") && req.post? && req.content_type&.include?("multipart/form-data")
  end

  # Rate limit invitation creation
  throttle("invitations/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path.match?(%r{/projects/\d+/invitations}) && req.post?
  end

  # Rate limit project creation
  throttle("projects/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/projects" && req.post?
  end

  # Rate limit password reset requests
  throttle("password_reset/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/passwords" && req.post?
  end

  # Rate limit signup attempts
  throttle("signup/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/signup" && req.post?
  end

  # General API rate limiting
  throttle("api/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets") || req.path.start_with?("/vite")
  end

  # Block suspicious requests
  blocklist("block-suspicious-requests") do |req|
    # Block requests with suspicious user agents
    suspicious_agents = [
      "sqlmap",
      "nmap",
      "nikto",
      "masscan",
      "zmap"
    ]

    user_agent = req.user_agent&.downcase
    suspicious_agents.any? { |agent| user_agent&.include?(agent) }
  end

  # Block requests with suspicious paths
  blocklist("block-suspicious-paths") do |req|
    suspicious_paths = [
      "/wp-admin",
      "/wp-login",
      "/admin",
      "/phpmyadmin",
      "/.env",
      "/config.php",
      "/shell.php"
    ]

    suspicious_paths.any? { |path| req.path.include?(path) }
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    retry_after = (env["rack.attack.match_data"] || {})[:period]

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ {
        error: "Rate limit exceeded",
        message: "Too many requests. Please try again later.",
        retry_after: retry_after
      }.to_json ]
    ]
  end

  # Custom response for blocked requests
  self.blocklisted_responder = lambda do |env|
    [
      403,
      { "Content-Type" => "application/json" },
      [ {
        error: "Forbidden",
        message: "Your request has been blocked."
      }.to_json ]
    ]
  end

  # Track requests for monitoring
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]

    case req.env["rack.attack.match_type"]
    when :throttle
      Rails.logger.warn "Rate limit exceeded: #{req.env['rack.attack.matched']} for IP #{req.ip}"
    when :blocklist
      Rails.logger.warn "Request blocked: #{req.env['rack.attack.matched']} for IP #{req.ip}"
    when :track
      Rails.logger.info "Request tracked: #{req.env['rack.attack.matched']} for IP #{req.ip}"
    end
  end
end

# Enable rack-attack in production and staging
Rails.application.config.middleware.use Rack::Attack if Rails.env.production? || Rails.env.staging?
