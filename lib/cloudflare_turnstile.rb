require "net/http"

class CloudflareTurnstile
  ALL_HTTP_ERRORS = [ Errno::ETIMEDOUT, Net::ReadTimeout, Net::OpenTimeout ].freeze

  def self.validate(payload, remote_ip)
    new(payload, remote_ip).validate
  end

  def initialize(payload, remote_ip)
    @payload = payload
    @remote_ip = remote_ip
  end

  def validate
    return false unless @payload
    return false unless secret_key

    response = validate_from_cloudflare
    response && response["success"]
  end

  private

  def secret_key
    @secret_key ||= Rails.application.credentials.dig(:turnstile, :cloudflare_secret_key) ||
                    ENV["CLOUDFLARE_TURNSTILE_SECRET_KEY"] ||
                    "1x0000000000000000000000000000000AA" # Test key for development
  end

  def validate_from_cloudflare
    retries ||= 0
    url = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    body = { secret: secret_key, response: @payload, remoteip: @remote_ip }
    response = Net::HTTP.post_form(url, body)
    JSON.parse(response.body)
  rescue *ALL_HTTP_ERRORS
    retry if (retries += 1) < 3
    # Return nil if all retries failed
    nil
  rescue => e
    # Log the error in development/test
    Rails.logger.error "Turnstile validation error: #{e.message}" if Rails.env.development? || Rails.env.test?
    nil
  end
end
