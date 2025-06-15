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
    policy.script_src  :self, :https

    # Allow @vite/client to hot reload javascript changes in development
    policy.script_src *policy.script_src, :unsafe_eval, "http://#{ViteRuby.config.host_with_port}" if Rails.env.development?

    # You may need to enable this in production as well depending on your setup.
    policy.script_src *policy.script_src, :blob if Rails.env.test?

    policy.style_src :self, :https
    # Allow @vite/client to hot reload style changes in development
    policy.style_src *policy.style_src, :unsafe_inline if Rails.env.development?

    # Allow connections to self and HTTPS
    policy.connect_src :self, :https

    # Allow @vite/client WebSocket connections in development
    policy.connect_src *policy.connect_src, "ws://#{ViteRuby.config.host_with_port}" if Rails.env.development?

    # Media sources
    policy.media_src :self, :https, :data

    # Form actions
    policy.form_action :self

    # Frame ancestors (prevent clickjacking)
    policy.frame_ancestors :none

    # Base URI
    policy.base_uri :self

    # Specify URI for violation reports
    policy.report_uri "/csp-violation-report-endpoint" if Rails.env.production?
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report violations without enforcing the policy in development
  config.content_security_policy_report_only = Rails.env.development?
end
