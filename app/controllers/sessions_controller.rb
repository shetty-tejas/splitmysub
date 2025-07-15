class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new magic_link verify_magic_link ]
  rate_limit to: 10, within: 3.minutes, only: :magic_link, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
    if authenticated?
      redirect_to root_path, flash: { notice: "You are already signed in." }
    else
      # Set meta tags for login page
      content_for :title, "Sign In - SplitMySub"
      content_for :description, "Sign in to your SplitMySub account to manage your shared subscriptions and split costs with friends."
      content_for :og_title, "Sign In - SplitMySub"
      content_for :og_description, "Access your SplitMySub account to track shared subscriptions and payments."

      render inertia: "sessions/login"
    end
  end

  def magic_link
    @user = User.find_by(email_address: params[:email_address])

    if @user
      # Generate and send magic link
      magic_link = MagicLink.generate_for_user(@user, expires_in: 30.minutes)
      MagicLinkMailer.send_magic_link(@user, magic_link).deliver_now

      flash[:notice] = "Magic link sent to your email address. Please check your inbox."
    else
      # Don't reveal if email exists or not for security
      flash[:notice] = "If an account with that email exists, a magic link has been sent."
    end

    redirect_to login_path
  end

  def verify_magic_link
    token = params[:token]
    magic_link = MagicLink.find_valid_token(token)

    if magic_link&.valid_for_use?
      # Use the magic link and start session
      magic_link.use!
      start_new_session_for(magic_link.user)

      # Check if this user verification is for completing an invitation
      if session[:pending_invitation_token].present?
        invitation_token = session.delete(:pending_invitation_token)
        invitation = Invitation.find_by(token: invitation_token)

        if invitation&.active?
          # Complete the invitation acceptance
          if invitation.accept!(magic_link.user)
            # Audit log: Email verification completed for invitation
            Rails.logger.info "AUDIT: Email verification completed for invitation - User: #{magic_link.user.id} (#{magic_link.user.email_address}), Project: #{invitation.project.id} (#{invitation.project.name}), Token: #{invitation_token[0..8]}..."

            flash[:notice] = "Email verified! Welcome to #{invitation.project.name}."
            redirect_to project_path(invitation.project)
          else
            flash[:alert] = "Unable to complete invitation. Please try again."
            redirect_to invitation_path(invitation_token)
          end
        else
          flash[:alert] = "Invitation has expired or is no longer valid."
          redirect_to after_authentication_url
        end
      else
        flash[:notice] = "Successfully signed in with magic link!"
        redirect_to after_authentication_url
      end
    else
      flash[:alert] = "Invalid or expired magic link. Please request a new one."
      redirect_to login_path
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, flash: { notice: "You have been signed out." }
  end

  private

    def after_authentication_url
    # Check if user was trying to accept an invitation
    if session[:invitation_token].present?
      invitation_token = session.delete(:invitation_token)
      invitation = Invitation.find_by(token: invitation_token)

      if invitation&.active?
        accept_invitation_path(invitation_token)
      else
        super
      end
    else
      super
    end
  end
end
