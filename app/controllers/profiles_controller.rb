class ProfilesController < ApplicationController
  def show
    render inertia: "profile/Show", props: {
      user: Current.user.as_json(only: [ :id, :email_address, :first_name, :last_name, :preferred_currency, :created_at, :telegram_user_id, :telegram_username, :telegram_notifications_enabled ])
    }
  end

  def edit
    render inertia: "profile/Edit", props: {
      user: Current.user.as_json(only: [ :id, :email_address, :first_name, :last_name, :preferred_currency, :telegram_user_id, :telegram_username, :telegram_notifications_enabled ]),
      currency_options: User.currency_options_for_select,
      telegram_verification_token: session[:telegram_verification_token]
    }
  end

  def update
    if Current.user.update(profile_params)
      flash[:notice] = "Profile updated successfully."
      redirect_to profile_path
    else
      render inertia: "profile/Edit", props: {
        user: Current.user.as_json(only: [ :id, :email_address, :first_name, :last_name, :preferred_currency, :telegram_user_id, :telegram_username, :telegram_notifications_enabled ]),
        currency_options: User.currency_options_for_select,
        telegram_verification_token: session[:telegram_verification_token],
        errors: Current.user.errors.as_json
      }
    end
  end

  # Telegram integration methods
  def generate_telegram_token
    token = Current.user.generate_telegram_verification_token
    session[:telegram_verification_token] = token

    render json: { token: token }
  end

  def check_telegram_status
    render json: { linked: Current.user.telegram_linked? }
  end

  def unlink_telegram
    Current.user.unlink_telegram_account!
    session.delete(:telegram_verification_token)
    flash[:notice] = "Telegram account unlinked successfully."
    redirect_to edit_profile_path
  end

  def toggle_telegram_notifications
    Current.user.toggle_telegram_notifications!

    render inertia: "profile/Edit", props: {
      user: Current.user.as_json(only: [ :id, :email_address, :first_name, :last_name, :preferred_currency, :telegram_user_id, :telegram_username, :telegram_notifications_enabled ]),
      currency_options: User.currency_options_for_select,
      telegram_verification_token: session[:telegram_verification_token]
    }
  end


  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :email_address, :preferred_currency)
  end
end
