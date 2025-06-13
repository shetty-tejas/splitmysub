class BillingCycleMailer < ApplicationMailer
  def new_cycles_created(project, billing_cycles)
    @project = project
    @billing_cycles = billing_cycles.sort_by(&:due_date)
    @project_owner = project.user

    mail(
      to: @project_owner.email_address,
      subject: "New billing cycles created for #{@project.name}"
    )
  end
end
