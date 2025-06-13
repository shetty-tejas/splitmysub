class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :preview_reminder, :reminder_settings ]
  before_action :ensure_owner, only: [ :edit, :update, :destroy, :preview_reminder, :reminder_settings ]

  def index
    @projects = Current.user.projects.includes(:project_memberships, :members)
    @member_projects = Current.user.member_projects.includes(:user, :project_memberships, :members)

    render inertia: "projects/index", props: {
      owned_projects: @projects.map { |project| project_json(project) },
      member_projects: @member_projects.map { |project| project_json(project) }
    }
  end

  def show
    unless @project.has_access?(Current.user)
      redirect_to projects_path, alert: "You don't have access to this project."
      return
    end

    render inertia: "projects/show", props: {
      project: detailed_project_json(@project)
    }
  end

  def new
    @project = Current.user.projects.build
    render inertia: "projects/new"
  end

  def create
    @project = Current.user.projects.build(project_params)

    if @project.save
      redirect_to @project, notice: "Project created successfully!"
    else
      redirect_to new_project_path, inertia: {
        errors: @project.errors.to_hash(true)
      }
    end
  end

  def edit
    render inertia: "projects/edit", props: {
      project: detailed_project_json(@project)
    }
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project updated successfully!"
    else
      redirect_to edit_project_path(@project), inertia: {
        errors: @project.errors.to_hash(true)
      }
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project deleted successfully!"
  end

  def preview_reminder
    escalation_level = params[:escalation_level]&.to_i || 1

    # Create a mock billing cycle for preview
    mock_billing_cycle = @project.billing_cycles.build(
      due_date: 7.days.from_now,
      total_amount: @project.cost
    )

    # Create a mock reminder schedule
    mock_reminder_schedule = @project.reminder_schedules.build(
      days_before: 7,
      escalation_level: escalation_level
    )

    # Generate preview email
    mailer = ReminderMailer.new
    mailer.instance_variable_set(:@billing_cycle, mock_billing_cycle)
    mailer.instance_variable_set(:@reminder_schedule, mock_reminder_schedule)
    mailer.instance_variable_set(:@user, Current.user)
    mailer.instance_variable_set(:@project, @project)
    mailer.instance_variable_set(:@amount_due, @project.cost_per_member)
    mailer.instance_variable_set(:@days_until_due, 7)
    mailer.instance_variable_set(:@escalation_level, escalation_level)
    mailer.instance_variable_set(:@escalation_description, mock_reminder_schedule.escalation_description)
    mailer.instance_variable_set(:@unsubscribe_token, "preview_token")

    # Determine template based on escalation level
    template = case escalation_level
    when 1
                 "gentle_reminder"
    when 2
                 "standard_reminder"
    when 3
                 "urgent_reminder"
    when 4, 5
                 "final_notice"
    else
                 "standard_reminder"
    end

    # Render the email template
    html_content = mailer.render_to_string(template: "reminder_mailer/#{template}")

    render html: html_content.html_safe
  end

  def reminder_settings
    render inertia: "projects/reminder_settings", props: {
      project: detailed_project_json(@project),
      reminder_schedules: @project.reminder_schedules.ordered_by_days.map do |schedule|
        {
          id: schedule.id,
          days_before: schedule.days_before,
          escalation_level: schedule.escalation_level,
          escalation_description: schedule.escalation_description,
          reminder_urgency: schedule.reminder_urgency
        }
      end
    }
  end

  private

  def set_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "Project not found."
  end

  def ensure_owner
    unless @project.is_owner?(Current.user)
      redirect_to projects_path, alert: "You can only edit projects you own."
    end
  end

  def project_params
    params.require(:project).permit(
      :name, :description, :cost, :billing_cycle, :renewal_date,
      :reminder_days, :payment_instructions, :subscription_url
    )
  end

  def project_json(project)
    {
      id: project.id,
      name: project.name,
      description: project.description,
      cost: project.cost,
      billing_cycle: project.billing_cycle,
      renewal_date: project.renewal_date,
      reminder_days: project.reminder_days,
      total_members: project.total_members,
      cost_per_member: project.cost_per_member,
      days_until_renewal: project.days_until_renewal,
      active: project.active?,
      expiring_soon: project.expiring_soon?,
      is_owner: project.is_owner?(Current.user),
      created_at: project.created_at,
      updated_at: project.updated_at
    }
  end

  def detailed_project_json(project)
    project_json(project).merge(
      payment_instructions: project.payment_instructions,
      subscription_url: project.subscription_url,
      owner: {
        id: project.owner.id,
        name: project.owner.full_name,
        email: project.owner.email_address
      },
      members: project.project_memberships.includes(:user).map do |membership|
        {
          id: membership.user.id,
          name: membership.user.full_name,
          email: membership.user.email_address,
          role: membership.role
        }
      end
    )
  end
end
