# Cloudflare Turnstile Configuration
module CloudflareTurnstileHelpers
  def cloudflare_turnstile_script_tag
    content_tag(:script, "", src: "https://challenges.cloudflare.com/turnstile/v0/api.js")
  end

  def cloudflare_turnstile_site_key
    # Use test keys in development, even if credentials are set
    if Rails.env.development?
      key = "1x00000000000000000000AA" # Test key for development (always passes)
    else
      key = Rails.application.credentials.dig(:turnstile, :cloudflare_site_key) ||
            ENV["CLOUDFLARE_TURNSTILE_SITE_KEY"] ||
            "1x00000000000000000000AA"
    end

    Rails.logger.info "Using Turnstile site key: #{key}"
    key
  end

  def cloudflare_turnstile_secret_key
    # Use test keys in development, even if credentials are set
    if Rails.env.development?
      secret = "1x0000000000000000000000000000000AA" # Test secret for development
    else
      secret = Rails.application.credentials.dig(:turnstile, :cloudflare_secret_key) ||
               ENV["CLOUDFLARE_TURNSTILE_SECRET_KEY"] ||
               "1x0000000000000000000000000000000AA"
    end

    Rails.logger.info "Using Turnstile secret key: #{secret.gsub(/.(?=.{4})/, '*')}" # Mask secret for logging
    secret
  end
end

# Include helpers in ApplicationController and views
ActionController::Base.include CloudflareTurnstileHelpers
ActionView::Base.include CloudflareTurnstileHelpers
