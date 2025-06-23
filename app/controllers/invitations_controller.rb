class InvitationsController < ApplicationController
  allow_unauthenticated_access only: [ :show, :accept, :confirm, :decline ]
  before_action :set_project, only: [ :index, :create, :update, :send_email, :destroy ]
  before_action :set_invitation, only: [ :show, :accept, :confirm, :decline, :update, :send_email, :destroy ]
  before_action :authorize_invitation_management, only: [ :index, :create, :destroy ]

  # GET /projects/:project_id/invitations
  def index
    @invitations = @project.invitations.includes(:invited_by)
                          .order(created_at: :desc)

    render inertia: "invitations/index", props: {
      project: project_with_details(@project),
      invitations: @invitations.map { |invitation| invitation_props(invitation) }
    }
  end

  # PATCH /projects/:project_id/invitations/:id
  def update
    if @invitation.update(invitation_params)
      respond_to do |format|
        format.json do
          render json: {
            invitation: @invitation,
            message: "Invitation updated successfully"
          }
        end
        format.html do
          redirect_back(fallback_location: project_path(@project),
                       notice: "Invitation updated successfully")
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            errors: @invitation.errors.full_messages
          }, status: :unprocessable_entity
        end
        format.html do
          redirect_back(fallback_location: project_path(@project),
                       alert: @invitation.errors.full_messages.join(", "))
        end
      end
    end
  end

  # POST /projects/:project_id/invitations/:id/send_email
  def send_email
    if @invitation.email.present?
      InvitationMailer.invite(@invitation).deliver_later

      respond_to do |format|
        format.json do
          render json: {
            message: "Invitation email sent to #{@invitation.email}"
          }
        end
        format.html do
          redirect_back(fallback_location: project_path(@project),
                       notice: "Invitation email sent to #{@invitation.email}")
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            error: "Cannot send email: no email address provided"
          }, status: :unprocessable_entity
        end
        format.html do
          redirect_back(fallback_location: project_path(@project),
                       alert: "Cannot send email: no email address provided")
        end
      end
    end
  end

  # POST /projects/:project_id/invitations
  def create
    @invitation = @project.invitations.build(invitation_params)
    @invitation.invited_by = Current.user

    if @invitation.save
      # Don't send invitation email automatically anymore
      # InvitationMailer.invite(@invitation).deliver_later

      respond_to do |format|
        format.json do
          render json: {
            invitation: invitation_props(@invitation),
            message: @invitation.email.present? ? "Invitation created for #{@invitation.email}" : "Invitation link created"
          }
        end
        format.html do
          redirect_back(fallback_location: project_path(@project),
                       notice: @invitation.email.present? ? "Invitation sent to #{@invitation.email}" : "Invitation link created")
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            errors: @invitation.errors.full_messages
          }, status: :unprocessable_entity
        end
        format.html do
          redirect_back(fallback_location: project_path(@project),
                       alert: @invitation.errors.full_messages.join(", "))
        end
      end
    end
  end

  # GET /invitations/:token
  def show
    if @invitation.nil?
      redirect_to root_path, alert: "Invalid invitation link"
      return
    end

    if @invitation.expired?
      render inertia: "invitations/expired", props: {
        invitation: invitation_props(@invitation),
        project: project_with_details(@invitation.project)
      }
      return
    end

    render inertia: "invitations/show", props: {
      invitation: invitation_props(@invitation),
      project: project_with_details(@invitation.project)
    }
  end

  # POST /invitations/:token/accept
  def accept
    if @invitation.nil?
      redirect_to root_path, alert: "Invalid invitation link"
      return
    end

    if @invitation.expired?
      render inertia: "invitations/expired", props: {
        invitation: invitation_props(@invitation),
        project: project_with_details(@invitation.project)
      }
      return
    end

    # Check if user with this email already exists
    existing_user = User.find_by(email_address: @invitation.email)

    if existing_user
      # If user exists and is logged in with matching email, accept directly
      if authenticated? && Current.user.email_address == @invitation.email
        # Accept invitation for existing logged-in user
        begin
          if @invitation.accept!(Current.user)
            redirect_to project_path(@invitation.project),
                       notice: "Welcome to #{@invitation.project.name}! You've successfully joined the project."
          else
            redirect_to invitation_path(@invitation.token),
                       alert: "Unable to accept invitation. Please try again."
          end
        rescue StandardError => e
          Rails.logger.error "Error accepting invitation: #{e.message}"
          redirect_to invitation_path(@invitation.token),
                     alert: "Something went wrong while accepting the invitation. Please try again."
        end
      else
        # User exists but not logged in, or logged in with different email
        # Log them in automatically and accept the invitation
        begin
          if @invitation.accept!(existing_user)
            # Log the user in using the same method as the authentication system
            start_new_session_for(existing_user)

            redirect_to project_path(@invitation.project),
                       notice: "Welcome back! You've successfully joined #{@invitation.project.name}."
          else
            redirect_to invitation_path(@invitation.token),
                       alert: "Unable to accept invitation. Please try again."
          end
        rescue StandardError => e
          Rails.logger.error "Error accepting invitation for existing user: #{e.message}"
          redirect_to invitation_path(@invitation.token),
                     alert: "Something went wrong while accepting the invitation. Please try again."
        end
      end
    else
      # New user - redirect to confirmation page
      render inertia: "invitations/confirm", props: {
        invitation: invitation_props(@invitation),
        project: project_with_details(@invitation.project),
        user_email: @invitation.email
      }
    end
  end

  # POST /invitations/:token/confirm
  def confirm
    if @invitation.nil?
      redirect_to root_path, alert: "Invalid invitation link"
      return
    end

    if @invitation.expired?
      render inertia: "invitations/expired", props: {
        invitation: invitation_props(@invitation),
        project: project_with_details(@invitation.project)
      }
      return
    end

    # Determine email to use: invitation email or user-provided email for link-only invitations
    user_email = @invitation.email.present? ? @invitation.email : params[:email]

    if user_email.blank?
      redirect_to invitation_path(@invitation.token),
                 alert: "Email address is required to create your account."
      return
    end

    # Check if user already exists
    if User.exists?(email_address: user_email)
      redirect_to invitation_path(@invitation.token),
                 alert: "An account with this email already exists. Please sign in instead."
      return
    end

    # Create new user and accept invitation
    begin
      # Double-check if user exists right before creation to handle race conditions
      if User.exists?(email_address: user_email)
        redirect_to invitation_path(@invitation.token),
                   alert: "An account with this email already exists. Please sign in instead."
        return
      end

      user = User.create!(
        email_address: user_email,
        first_name: params[:first_name],
        last_name: params[:last_name]
      )

      Rails.logger.info "User created successfully: #{user.id}"

      # Accept the invitation
      if @invitation.accept!(user)
        # Log the user in using the same method as the authentication system
        start_new_session_for(user)

        redirect_to project_path(@invitation.project),
                   notice: "Welcome to SplitSub! Your account has been created and you've joined #{@invitation.project.name}."
      else
        Rails.logger.error "Failed to accept invitation for user: #{user.id}"
        user.destroy # Clean up if invitation acceptance fails
        redirect_to invitation_path(@invitation.token),
                   alert: "Unable to accept invitation. Please try again."
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "RecordInvalid error: #{e.message}"
      Rails.logger.error "Validation errors: #{e.record.errors.full_messages}"
      redirect_to invitation_path(@invitation.token),
                 alert: "Unable to create account: #{e.record.errors.full_messages.join(', ')}"
    rescue ActiveRecord::RecordNotUnique => e
      Rails.logger.error "RecordNotUnique error: #{e.message}"
      redirect_to invitation_path(@invitation.token),
                 alert: "An account with this email already exists. Please contact the project owner."
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error "StatementInvalid error: #{e.message}"
      if e.message.include?("UNIQUE constraint failed") || e.message.include?("duplicate key")
        redirect_to invitation_path(@invitation.token),
                   alert: "An account with this email already exists. Please contact the project owner."
      else
        redirect_to invitation_path(@invitation.token),
                   alert: "Something went wrong while creating your account. Please try again or contact support."
      end
    rescue StandardError => e
      Rails.logger.error "Error in invitation confirmation: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to invitation_path(@invitation.token),
                 alert: "Something went wrong while creating your account. Please try again or contact support."
    end
  end

  # POST /invitations/:token/decline
  def decline
    if @invitation.nil?
      redirect_to root_path, alert: "Invalid invitation link"
      return
    end

    if @invitation.expired?
      render inertia: "invitations/expired", props: {
        invitation: invitation_props(@invitation),
        project: project_with_details(@invitation.project)
      }
      return
    end

    if @invitation.decline!
      render inertia: "invitations/declined", props: {
        invitation: invitation_props(@invitation),
        project: project_with_details(@invitation.project)
      }
    else
      redirect_to invitation_path(@invitation.token),
                 alert: "Unable to decline invitation. Please try again."
    end
  end

  # DELETE /projects/:project_id/invitations/:id
  def destroy
    @invitation.destroy

    redirect_back(fallback_location: project_invitations_path(@project),
                 notice: "Invitation cancelled")
  end

  private

  def set_project
    @project = Current.user.projects.find_by!(slug: params[:project_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to dashboard_path, alert: "Project not found"
  end

  def set_invitation
    # For public routes that use :token parameter
    if params[:token]
      @invitation = Invitation.includes(:invited_by).find_by_invitation_token(params[:token])
    else
      # For project-scoped routes that use :id parameter (database ID)
      @invitation = Invitation.includes(:invited_by).find_by(id: params[:id])
    end
  end

  def authorize_invitation_management
    ensure_project_owner!(@project)
  end

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end

  def invitation_props(invitation)
    {
      id: invitation.id,
      email: invitation.email,
      role: invitation.role,
      status: invitation.status,
      expires_at: invitation.expires_at.iso8601,
      created_at: invitation.created_at.iso8601,
      invited_by: {
        id: invitation.invited_by.id,
        name: invitation.invited_by.full_name,
        email: invitation.invited_by.email_address
      },
      token: invitation.token
    }
  end

  def project_with_details(project)
    {
      id: project.id,
      name: project.name,
      description: project.description,
      cost: project.cost,
      billing_cycle: project.billing_cycle,
      renewal_date: project.renewal_date.iso8601,
      reminder_days: project.reminder_days,
      subscription_url: project.subscription_url,
      payment_instructions: project.payment_instructions,
      active: project.active?,
      expiring_soon: project.expiring_soon?,
      days_until_renewal: project.days_until_renewal,
      total_members: project.total_members,
      cost_per_member: project.cost_per_member,
      is_owner: Current.user ? project.is_owner?(Current.user) : false,
      created_at: project.created_at.iso8601,
      updated_at: project.updated_at.iso8601,
      owner: {
        id: project.user.id,
        name: project.user.full_name,
        email: project.user.email_address
      },
      members: project.project_memberships.includes(:user).map do |membership|
        {
          id: membership.user.id,
          name: membership.user.full_name,
          email: membership.user.email_address,
          role: membership.role
        }
      end
    }
  end
end
