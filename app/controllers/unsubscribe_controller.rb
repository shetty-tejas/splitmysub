class UnsubscribeController < ApplicationController
  allow_unauthenticated_access only: [ :show, :create ]

  def show
    @token = params[:token]
    @unsubscribe_data = decode_unsubscribe_token(@token)

    if @unsubscribe_data
      @user = User.find_by(id: @unsubscribe_data["user_id"])
      @project = Project.find(@unsubscribe_data["project_id"])

      if @user && @project
        render :show
      else
        render :invalid_token
      end
    else
      render :invalid_token
    end
  rescue StandardError => e
    Rails.logger.error "Unsubscribe error: #{e.message}"
    render :invalid_token
  end

  def create
    @token = params[:token]
    @unsubscribe_data = decode_unsubscribe_token(@token)

    if @unsubscribe_data
      user = User.find_by(id: @unsubscribe_data["user_id"])
      project = Project.find(@unsubscribe_data["project_id"])

      if user && project
        # Create or update user preferences to unsubscribe from this project
        preferences = user.preferences || {}
        preferences["unsubscribed_projects"] ||= []

        unless preferences["unsubscribed_projects"].include?(project.id)
          preferences["unsubscribed_projects"] << project.id
          user.update!(preferences: preferences)
        end

        Rails.logger.info "User #{user.email_address} unsubscribed from reminders for project #{project.name}"

        redirect_to unsubscribe_path(token: @token), notice: "You have been successfully unsubscribed from reminders for this project."
      else
        redirect_to unsubscribe_path(token: @token), alert: "Invalid unsubscribe request."
      end
    else
      redirect_to unsubscribe_path(token: @token), alert: "Invalid unsubscribe token."
    end
  rescue StandardError => e
    Rails.logger.error "Unsubscribe error: #{e.message}"
    redirect_to unsubscribe_path(token: @token), alert: "An error occurred while processing your request."
  end

  private

  def decode_unsubscribe_token(token)
    return nil unless token.present?

    begin
      decoded_data = Base64.urlsafe_decode64(token)
      JSON.parse(decoded_data)
    rescue StandardError => e
      Rails.logger.error "Failed to decode unsubscribe token: #{e.message}"
      nil
    end
  end
end
