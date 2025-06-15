class ProfilesController < ApplicationController
  def show
    render inertia: "profile/Show", props: {
      user: Current.user.as_json(only: [ :id, :email_address, :first_name, :last_name, :created_at ])
    }
  end

  def edit
    render inertia: "profile/Edit", props: {
      user: Current.user.as_json(only: [ :id, :email_address, :first_name, :last_name ])
    }
  end

  def update
    if Current.user.update(profile_params)
      flash[:notice] = "Profile updated successfully."
      redirect_to profile_path
    else
      render inertia: "profile/Edit", props: {
        user: Current.user.as_json(only: [ :id, :email_address, :first_name, :last_name ]),
        errors: Current.user.errors.as_json
      }
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :email_address)
  end
end
