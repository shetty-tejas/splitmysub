require "csv"

class DashboardController < ApplicationController
  def index
    @projects = Current.user.projects.includes(:project_memberships, :members)
    @member_projects = Current.user.member_projects.includes(:user, :project_memberships, :members)

    render inertia: "dashboard/Index", props: {
      owned_projects: @projects.map { |project| project_json(project) },
      member_projects: @member_projects.map { |project| project_json(project) }
    }
  end

  def payment_history
    @payments = Current.user.payments
                           .includes(billing_cycle: :project)
                           .order(created_at: :desc)

    # Apply filters
    @payments = @payments.where(status: params[:status]) if params[:status].present?
    @payments = @payments.joins(billing_cycle: :project)
                        .where("projects.name LIKE ?", "%#{params[:search]}%") if params[:search].present?

    # Apply date range filter
    if params[:date_from].present?
      @payments = @payments.where("payments.created_at >= ?", Date.parse(params[:date_from]))
    end
    if params[:date_to].present?
      @payments = @payments.where("payments.created_at <= ?", Date.parse(params[:date_to]).end_of_day)
    end

    # Pagination
    @payments = @payments.page(params[:page]).per(20)

    render inertia: "dashboard/PaymentHistory", props: {
      payments: @payments.map { |p| payment_props(p) },
      pagination: pagination_props(@payments),
      filters: {
        status: params[:status],
        search: params[:search],
        date_from: params[:date_from],
        date_to: params[:date_to]
      }
    }
  end

  def upcoming_payments
    # Get all projects the user is involved in
    owned_project_ids = Current.user.projects.pluck(:id)
    member_project_ids = Current.user.member_projects.pluck(:id)
    all_project_ids = (owned_project_ids + member_project_ids).uniq

    # Get upcoming billing cycles
    @upcoming_cycles = BillingCycle.joins(:project)
                                  .where(project_id: all_project_ids)
                                  .upcoming
                                  .order(:due_date)
                                  .includes(:project, :payments)

    # Group by month for calendar view
    @calendar_data = @upcoming_cycles.group_by { |cycle| cycle.due_date.beginning_of_month }

    render inertia: "dashboard/UpcomingPayments", props: {
      upcoming_cycles: @upcoming_cycles.map { |c| billing_cycle_props(c) },
      calendar_data: @calendar_data.transform_values { |cycles| cycles.map { |c| billing_cycle_props(c) } }
    }
  end

  def analytics
    # Calculate analytics data
    @analytics = {
      monthly_spending: calculate_monthly_spending,
      payment_status_breakdown: calculate_payment_status_breakdown,
      project_cost_breakdown: calculate_project_cost_breakdown,
      savings_analysis: calculate_savings_analysis
    }

    render inertia: "dashboard/Analytics", props: {
      analytics: @analytics
    }
  end

  def export_payments
    @payments = Current.user.payments
                           .includes(billing_cycle: :project)
                           .order(created_at: :desc)

    # Apply same filters as payment_history
    @payments = @payments.where(status: params[:status]) if params[:status].present?
    @payments = @payments.joins(billing_cycle: :project)
                        .where("projects.name LIKE ?", "%#{params[:search]}%") if params[:search].present?

    if params[:date_from].present?
      @payments = @payments.where("payments.created_at >= ?", Date.parse(params[:date_from]))
    end
    if params[:date_to].present?
      @payments = @payments.where("payments.created_at <= ?", Date.parse(params[:date_to]).end_of_day)
    end

    respond_to do |format|
      format.csv do
        send_data generate_csv(@payments),
                  filename: "payment_history_#{Date.current}.csv",
                  type: "text/csv"
      end
    end
  end

  private

  def project_json(project)
    {
      id: project.id,
      slug: project.slug,
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

  def calculate_dashboard_stats
    # Get project IDs for both owned and member projects
    owned_project_ids = Current.user.projects.pluck(:id)
    member_project_ids = Current.user.member_projects.pluck(:id)
    all_project_ids = (owned_project_ids + member_project_ids).uniq

    {
      total_projects: all_project_ids.count,
      owned_projects: owned_project_ids.count,
      member_projects: member_project_ids.count,
      total_monthly_cost: Project.where(id: all_project_ids, billing_cycle: "monthly").sum(:cost),
      total_payments_made: Current.user.payments.confirmed.count,
      pending_payments: Current.user.payments.pending.count,
      overdue_payments: Current.user.payments.joins(:billing_cycle)
                                           .where("billing_cycles.due_date < ?", Date.current)
                                           .where(status: "pending").count,
      total_amount_paid: Current.user.payments.confirmed.sum(:amount),
      upcoming_due_soon: BillingCycle.joins(:project)
                                    .where(project_id: all_project_ids)
                                    .due_soon(7)
                                    .count
    }
  end

  def calculate_monthly_spending
    # Get last 12 months of payment data
    months = (0..11).map { |i| i.months.ago.beginning_of_month }

    months.map do |month|
      amount = Current.user.payments
                          .confirmed
                          .where(created_at: month..month.end_of_month)
                          .sum(:amount)
      {
        month: month.strftime("%b %Y"),
        amount: amount
      }
    end.reverse
  end

  def calculate_payment_status_breakdown
    {
      confirmed: Current.user.payments.confirmed.count,
      pending: Current.user.payments.pending.count,
      rejected: Current.user.payments.rejected.count
    }
  end

  def calculate_project_cost_breakdown
    owned_project_ids = Current.user.projects.pluck(:id)
    member_project_ids = Current.user.member_projects.pluck(:id)
    all_project_ids = (owned_project_ids + member_project_ids).uniq

    # Pre-fetch project memberships to avoid N+1 queries
    all_projects = Project.where(id: all_project_ids)
                         .includes(:project_memberships)

    all_projects.map do |project|
      user_cost = if owned_project_ids.include?(project.id)
        project.cost # Owner pays full cost
      else
        project.cost_per_member # Member pays per-member cost
      end

      {
        name: project.name,
        cost: user_cost,
        currency: project.currency,
        billing_cycle: project.billing_cycle,
        role: owned_project_ids.include?(project.id) ? "owner" : "member"
      }
    end
  end

  def calculate_savings_analysis
    member_projects = Current.user.member_projects

    total_savings = member_projects.sum do |project|
      project.cost - project.cost_per_member
    end

    {
      monthly_savings: total_savings,
      yearly_savings: total_savings * 12,
      projects_count: member_projects.count
    }
  end

  def project_with_stats(project)
    # Cache owned project IDs to avoid repeated queries
    @owned_project_ids ||= Current.user.projects.pluck(:id)

    {
      id: project.id,
      slug: project.slug,
      name: project.name,
      description: project.description,
      cost: project.cost,
      currency: project.currency,
      billing_cycle: project.billing_cycle,
      renewal_date: project.renewal_date,
      cost_per_member: project.cost_per_member,
      total_members: project.total_members,
      is_owner: @owned_project_ids.include?(project.id),
      next_billing_cycle: project.billing_cycles.upcoming.first&.due_date,
      payment_status: user_payment_status_for_project(project),
      overdue_cycles: project.billing_cycles.overdue.count
    }
  end

  def user_payment_status_for_project(project)
    # Get the most recent billing cycle for this project
    recent_cycle = project.billing_cycles.order(due_date: :desc).first
    return "no_cycles" unless recent_cycle

    # Check if user has paid for the most recent cycle
    user_payment = Current.user.payments.find_by(billing_cycle: recent_cycle)

    if user_payment
      user_payment.status
    elsif recent_cycle.due_date < Date.current
      "overdue"
    else
      "pending"
    end
  end

  def payment_props(payment)
    {
      id: payment.id,
      amount: payment.amount,
      status: payment.status,
      transaction_id: payment.transaction_id,
      notes: payment.notes,
      created_at: payment.created_at,
      user: payment.user ? {
        id: payment.user.id,
        email_address: payment.user.email_address,
        name: payment.user.full_name
      } : nil,
      project: project_json(payment.project),
      billing_cycle: billing_cycle_props(payment.billing_cycle)
    }
  end

  def billing_cycle_props(billing_cycle)
    {
      id: billing_cycle.id,
      cycle_month: billing_cycle.cycle_month,
      cycle_year: billing_cycle.cycle_year,
      total_amount: billing_cycle.total_amount,
      due_date: billing_cycle.due_date,
      total_paid: billing_cycle.total_paid,
      amount_remaining: billing_cycle.amount_remaining,
      payment_status: billing_cycle.payment_status,
      overdue: billing_cycle.overdue?,
      days_until_due: billing_cycle.days_until_due
    }
  end

  def pagination_props(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end

  def generate_csv(payments)
    CSV.generate(headers: true) do |csv|
      csv << [ "Date", "Project", "Amount", "Status", "Due Date", "Transaction ID", "Notes" ]

      payments.each do |payment|
        csv << [
          payment.created_at.strftime("%Y-%m-%d"),
          payment.billing_cycle.project.name,
          payment.amount,
          payment.status.humanize,
          payment.billing_cycle.due_date,
          payment.transaction_id,
          payment.confirmation_notes
        ]
      end
    end
  end
end
