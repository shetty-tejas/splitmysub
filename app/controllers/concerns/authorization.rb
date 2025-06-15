module Authorization
  extend ActiveSupport::Concern

  class AuthorizationError < StandardError; end

  included do
    rescue_from AuthorizationError, with: :handle_authorization_error
  end

  private

  def authorize!(action, resource = nil)
    unless can?(action, resource)
      raise AuthorizationError, "You are not authorized to #{action} this resource"
    end
  end

  def can?(action, resource = nil)
    case resource
    when Project
      can_access_project?(action, resource)
    when Payment
      can_access_payment?(action, resource)
    when BillingCycle
      can_access_billing_cycle?(action, resource)
    when Invitation
      can_access_invitation?(action, resource)
    when User
      can_access_user?(action, resource)
    else
      false
    end
  end

  def ensure_project_owner!(project)
    authorize!(:manage, project)
  end

  def ensure_project_access!(project)
    authorize!(:read, project)
  end

  def ensure_payment_access!(payment)
    authorize!(:read, payment)
  end

  def ensure_admin!
    unless current_user_admin?
      raise AuthorizationError, "Admin access required"
    end
  end

  def current_user_admin?
    # For now, we'll consider the first user as admin
    # In a real app, you'd have an admin flag or role system
    Current.user&.id == 1
  end

  def can_access_project?(action, project)
    return false unless Current.user && project

    case action
    when :read, :show
      project.has_access?(Current.user)
    when :create
      true # Any authenticated user can create projects
    when :update, :edit, :manage, :destroy, :delete
      project.is_owner?(Current.user)
    when :invite_members
      project.is_owner?(Current.user)
    when :view_payments
      project.has_access?(Current.user)
    else
      false
    end
  end

  def can_access_payment?(action, payment)
    return false unless Current.user && payment

    case action
    when :read, :show
      # User can access their own payments or if they're the project owner
      payment.user == Current.user ||
        (payment.project&.is_owner?(Current.user))
    when :create
      # User can create payments for projects they're a member of
      payment.billing_cycle&.project&.has_access?(Current.user)
    when :update, :edit
      # Only the payment creator can update their payment
      payment.user == Current.user
    when :destroy, :delete
      # Payment creator or project owner can delete
      payment.user == Current.user ||
        (payment.project&.is_owner?(Current.user))
    when :confirm
      # Only project owner can confirm payments
      payment.project&.is_owner?(Current.user)
    when :download_evidence
      # Same as read access
      payment.user == Current.user ||
        (payment.project&.is_owner?(Current.user))
    else
      false
    end
  end

  def can_access_billing_cycle?(action, billing_cycle)
    return false unless Current.user && billing_cycle

    case action
    when :read, :show
      billing_cycle.project&.has_access?(Current.user)
    when :create, :update, :edit, :destroy, :delete, :manage
      billing_cycle.project&.is_owner?(Current.user)
    else
      false
    end
  end

  def can_access_invitation?(action, invitation)
    return false unless Current.user && invitation

    case action
    when :read, :show
      # User can see invitations sent to them or created by them
      invitation.email == Current.user.email_address ||
        invitation.project&.is_owner?(Current.user)
    when :create
      # Only project owners can create invitations
      invitation.project&.is_owner?(Current.user)
    when :accept
      # Only the invited user can accept
      invitation.email == Current.user.email_address
    when :destroy, :delete, :cancel
      # Project owner or invited user can cancel
      invitation.project&.is_owner?(Current.user) ||
        invitation.email == Current.user.email_address
    else
      false
    end
  end

  def can_access_user?(action, user)
    return false unless Current.user && user

    case action
    when :read, :show
      # Users can view their own profile or if they share a project
      user == Current.user || shares_project_with?(user)
    when :update, :edit
      # Users can only edit their own profile
      user == Current.user
    when :destroy, :delete
      # Users can delete their own account or admin can delete
      user == Current.user || current_user_admin?
    else
      false
    end
  end

  def shares_project_with?(user)
    return false unless Current.user && user

    # Check if users share any projects (as owner/member)
    current_user_projects = Current.user.projects.pluck(:id) +
                           Current.user.member_projects.pluck(:id)
    other_user_projects = user.projects.pluck(:id) +
                         user.member_projects.pluck(:id)

    (current_user_projects & other_user_projects).any?
  end

  def handle_authorization_error(exception)
    Rails.logger.warn "Authorization Error: #{exception.message} for user #{Current.user&.id}"

    respond_to do |format|
      format.html do
        redirect_back(
          fallback_location: root_path,
          alert: "You don't have permission to perform this action."
        )
      end
      format.json do
        render json: {
          error: "Unauthorized",
          message: "You don't have permission to perform this action."
        }, status: :forbidden
      end
    end
  end

  # Helper method to get the current user's projects (owned + member)
  def current_user_accessible_projects
    return Project.none unless Current.user

    owned_projects = Current.user.projects
    member_projects = Current.user.member_projects

    Project.where(id: owned_projects.pluck(:id) + member_projects.pluck(:id))
  end

  # Helper method to scope resources by user access
  def scope_by_user_access(relation)
    case relation.model.name
    when "Project"
      current_user_accessible_projects.where(id: relation.pluck(:id))
    when "Payment"
      relation.joins(billing_cycle: :project)
              .where(
                "payments.user_id = ? OR projects.user_id = ?",
                Current.user.id,
                Current.user.id
              )
    else
      relation.none
    end
  end
end
