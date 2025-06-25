# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none

    # Allow Cloudflare Turnstile scripts
    policy.script_src  :self, :https, "https://challenges.cloudflare.com"

    # Allow @vite/client to hot reload javascript changes in development
    policy.script_src *policy.script_src, :unsafe_eval, "http://#{ViteRuby.config.host_with_port}" if Rails.env.development?

    # You may need to enable this in production as well depending on your setup.
    policy.script_src *policy.script_src, :blob if Rails.env.test?

    # Allow styles from self, HTTPS, and inline styles for Turnstile widget
    policy.style_src :self, :https, :unsafe_inline
    # Allow @vite/client to hot reload style changes in development
    policy.style_src *policy.style_src, :unsafe_inline if Rails.env.development?
    # Allow inline styles for email templates in production (required for email client compatibility)
    policy.style_src *policy.style_src, :unsafe_inline if Rails.env.production?

    # Allow connections to self, HTTPS, and Cloudflare Turnstile
    policy.connect_src :self, :https, "https://challenges.cloudflare.com"

    # Allow @vite/client WebSocket connections in development
    policy.connect_src *policy.connect_src, "ws://#{ViteRuby.config.host_with_port}" if Rails.env.development?

    # Media sources
    policy.media_src :self, :https, :data

    # Form actions
    policy.form_action :self

    # Frame ancestors (prevent clickjacking) - but allow Cloudflare Turnstile frames
    policy.frame_ancestors :none
    policy.frame_src "https://challenges.cloudflare.com"

    # Base URI
    policy.base_uri :self

    # Specify URI for violation reports
    policy.report_uri "/csp-violation-report-endpoint" if Rails.env.production?
  end

  # Skip CSP for email templates (they need inline styles to work across email clients)
  config.content_security_policy_skip_if = lambda do |request|
    # Skip CSP for mailer previews and when rendering emails
    request.path.include?("rails/mailers") ||
    request.env["action_mailer.rendering"] == true ||
    request.env["HTTP_USER_AGENT"]&.include?("Email")
  end

  # Generate session nonces for permitted importmap and inline scripts only.
  # Note: Nonces are not used for style-src to allow unsafe-inline for email templates
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Report violations without enforcing the policy in development
  config.content_security_policy_report_only = Rails.env.development?
end
