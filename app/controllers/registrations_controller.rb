class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    if authenticated?
      redirect_to root_path, flash: { alert: "You are already signed in." }
    else
      render inertia: "registrations/signup"
    end
  end

  def create
    # Validate Turnstile first
    unless verify_turnstile_token(params[:"cf-turnstile-response"])
      redirect_to signup_path, inertia: {
        errors: { "cf-turnstile-response" => [ "Please complete the security verification" ] }
      }
      return
    end

    user = User.new(user_params)

    if user.save
      # Send magic link for account verification instead of auto-login
      magic_link = MagicLink.generate_for_user(user, expires_in: 30.minutes)
      MagicLinkMailer.send_magic_link(user, magic_link).deliver_now

      flash[:notice] = "Account created! Please check your email for a magic link to sign in."
      redirect_to login_path
    else
      redirect_to signup_path, inertia: {
        errors: user.errors.to_hash(true) # Convert ActiveModel::Errors to a hash for Inertia
      }
    end
  end

  private

  def user_params
    params.permit(
      :email_address,
      :first_name,
      :last_name
    )
  end

  def verify_turnstile_token(token)
    return false if token.blank?

    CloudflareTurnstile.validate(token, request.remote_ip)
  end
end
