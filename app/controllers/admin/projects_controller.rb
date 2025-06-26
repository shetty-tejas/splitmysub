class Admin::ProjectsController < Admin::BaseController
  # GET /admin/projects
  def index
    @projects = Project.includes(:user, :project_memberships, :members)
                      .order(:created_at)

    render inertia: "admin/Projects/Index", props: {
      projects: projects_props(@projects),
      total_projects: @projects.count,
      total_users: User.count,
      total_memberships: ProjectMembership.count
    }
  end

  private

  def projects_props(projects)
    projects.map do |project|
      {
        id: project.id,
        name: project.name,
        slug: project.slug,
        cost: project.cost,
        currency: project.currency,
        billing_cycle: project.billing_cycle,
        renewal_date: project.renewal_date,
        description: project.description,
        subscription_url: project.subscription_url,
        created_at: project.created_at,
        updated_at: project.updated_at,
        owner: {
          id: project.user.id,
          name: project.user.full_name,
          email: project.user.email_address
        },
        members: project.members.map do |member|
          {
            id: member.id,
            name: member.full_name,
            email: member.email_address,
            joined_at: project.project_memberships.find_by(user: member)&.created_at
          }
        end,
        total_members: project.total_members,
        cost_per_member: project.cost_per_member,
        formatted_cost: project.format_cost,
        formatted_cost_per_member: project.format_cost_per_member,
        active: project.active?,
        days_until_renewal: project.days_until_renewal
      }
    end
  end
end
