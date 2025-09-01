class BillingCyclesController < ApplicationController
  before_action :set_project, only: [ :index, :show, :new, :create, :edit, :update, :destroy, :generate_upcoming, :archive, :unarchive, :adjust ]
  before_action :set_billing_cycle, only: [ :show, :edit, :update, :destroy, :archive, :unarchive, :adjust ]
  before_action :ensure_project_access, only: [ :index, :show ]
  before_action :ensure_project_owner, only: [ :new, :create, :edit, :update, :destroy, :generate_upcoming, :archive, :unarchive, :adjust ]

  def index
    @billing_cycles = @project.billing_cycles.includes(:payments)

    # Apply archive filter
    if params[:show_archived] == "true"
      @billing_cycles = @billing_cycles.archived
    else
      @billing_cycles = @billing_cycles.active
    end

    @billing_cycles = @billing_cycles.order(due_date: :desc)

    # Apply filters
    @billing_cycles = @billing_cycles.upcoming if params[:filter] == "upcoming"
    @billing_cycles = @billing_cycles.overdue if params[:filter] == "overdue"
    if params[:filter] == "due_soon"
      days = params[:days]&.to_i || BillingConfig.current.due_soon_days
      @billing_cycles = @billing_cycles.where(id: BillingCycle.due_soon(days).pluck(:id))
    end

    # Apply search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @billing_cycles = @billing_cycles.where("CAST(total_amount AS TEXT) LIKE ?", search_term)
    end

    # Apply sorting
    case params[:sort]
    when "due_date_asc"
      @billing_cycles = @billing_cycles.order(due_date: :asc)
    when "amount_desc"
      @billing_cycles = @billing_cycles.order(total_amount: :desc)
    when "amount_asc"
      @billing_cycles = @billing_cycles.order(total_amount: :asc)
    else
      @billing_cycles = @billing_cycles.order(due_date: :desc)
    end

    begin
      stats = billing_cycle_stats
    rescue => e
      Rails.logger.error "Error calculating billing cycle stats: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      stats = {} # Provide empty hash as fallback
    end

    render inertia: "billing_cycles/Index", props: {
      project: project_props(@project),
      billing_cycles: @billing_cycles.map { |cycle| billing_cycle_props(cycle) },
      stats: stats,
      filters: {
        filter: params[:filter],
        search: params[:search],
        sort: params[:sort],
        show_archived: params[:show_archived]
      },
      user_permissions: {
        is_owner: @project.is_owner?(Current.user),
        is_member: @project.is_member?(Current.user),
        can_manage: @project.is_owner?(Current.user)
      }
    }
  end

  def show
    @payments = @billing_cycle.payments.includes(:user, :evidence_attachment)
                              .order(created_at: :desc)

    render inertia: "billing_cycles/Show", props: {
      project: project_props(@project),
      billing_cycle: detailed_billing_cycle_props(@billing_cycle),
      payments: @payments.map { |payment| payment_props(payment) },
      payment_stats: cycle_payment_stats(@billing_cycle),
      user_permissions: {
        is_owner: @project.is_owner?(Current.user),
        is_member: @project.is_member?(Current.user),
        can_manage: @project.is_owner?(Current.user),
        can_pay: @billing_cycle.user_payment_pending?(Current.user)
      }
    }
  end

  def new
    @billing_cycle = @project.billing_cycles.build(
      due_date: @project.next_billing_cycle,
      total_amount: @project.cost
    )

    render inertia: "billing_cycles/New", props: {
      project: project_props(@project),
      billing_cycle: billing_cycle_props(@billing_cycle)
    }
  end

  def create
    @billing_cycle = @project.billing_cycles.build(billing_cycle_params)

    if @billing_cycle.save
      # Schedule reminders for the new billing cycle
      ReminderService.schedule_reminders_for_billing_cycle(@billing_cycle)

      redirect_to [ @project, @billing_cycle ], notice: "Billing cycle created successfully!"
    else
      render inertia: "billing_cycles/New", props: {
        project: project_props(@project),
        billing_cycle: billing_cycle_props(@billing_cycle),
        errors: @billing_cycle.errors.full_messages
      }
    end
  end

  def edit
    render inertia: "billing_cycles/Edit", props: {
      project: project_props(@project),
      billing_cycle: billing_cycle_props(@billing_cycle)
    }
  end

  def update
    if @billing_cycle.update(billing_cycle_params)
      redirect_to [ @project, @billing_cycle ], notice: "Billing cycle updated successfully!"
    else
      render inertia: "billing_cycles/Edit", props: {
        project: project_props(@project),
        billing_cycle: billing_cycle_props(@billing_cycle),
        errors: @billing_cycle.errors.full_messages
      }
    end
  end

  def destroy
    @billing_cycle.destroy
    redirect_to project_billing_cycles_path(@project), notice: "Billing cycle deleted successfully!"
  end

  def generate_upcoming
    generated_cycles = BillingCycleGeneratorService.generate_upcoming_cycles(@project)

    if generated_cycles.any?
      redirect_to project_billing_cycles_path(@project),
                  notice: "Generated #{generated_cycles.count} upcoming billing cycle(s)!"
    else
      redirect_to project_billing_cycles_path(@project),
                  notice: "No new billing cycles needed at this time."
    end
  end

  def archive
    @billing_cycle.archive!
    redirect_to project_billing_cycles_path(@project), notice: "Billing cycle archived successfully!"
  end

  def unarchive
    @billing_cycle.unarchive!
    redirect_to project_billing_cycles_path(@project), notice: "Billing cycle unarchived successfully!"
  end

  def adjust
    if request.post?
      adjustment_params = params.require(:adjustment).permit(:new_amount, :new_due_date, :reason)

      begin
        if adjustment_params[:new_amount].present?
          @billing_cycle.adjust_amount!(adjustment_params[:new_amount].to_f, adjustment_params[:reason])
        end

        if adjustment_params[:new_due_date].present?
          @billing_cycle.adjust_due_date!(Date.parse(adjustment_params[:new_due_date]), adjustment_params[:reason])
        end

        redirect_to [ @project, @billing_cycle ], notice: "Billing cycle adjusted successfully!"
      rescue => e
        redirect_to [ @project, @billing_cycle ], alert: "Failed to adjust billing cycle: #{e.message}"
      end
    else
      render inertia: "billing_cycles/Adjust", props: {
        project: project_props(@project),
        billing_cycle: billing_cycle_props(@billing_cycle)
      }
    end
  end

  private

  def set_project
    @project = Current.user.projects.find_by!(slug: params[:project_id])
  rescue ActiveRecord::RecordNotFound
    # Check if user is a member of the project by slug
    project = Project.find_by(slug: params[:project_id])
    if project && project.is_member?(Current.user)
      @project = project
    else
      redirect_to root_path, alert: "Project not found or access denied."
    end
  end

  def set_billing_cycle
    @billing_cycle = @project.billing_cycles.find(params[:id])
  end

  def ensure_project_access
    unless @project.is_owner?(Current.user) || @project.is_member?(Current.user)
      redirect_to root_path, alert: "Access denied."
    end
  end

  def ensure_project_owner
    unless @project.is_owner?(Current.user)
      redirect_to root_path, alert: "Access denied."
    end
  end

  def billing_cycle_params
    params.require(:billing_cycle).permit(:due_date, :total_amount)
  end

  def project_props(project)
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
      is_owner: project.is_owner?(Current.user)
    }
  end

  def billing_cycle_props(billing_cycle)
    {
      id: billing_cycle.id,
      cycle_month: billing_cycle.cycle_month,
      cycle_year: billing_cycle.cycle_year,
      total_amount: billing_cycle.total_amount,
      due_date: billing_cycle.due_date,
      created_at: billing_cycle.created_at,
      updated_at: billing_cycle.updated_at,
      total_paid: billing_cycle.total_paid,
      fully_paid: billing_cycle.fully_paid?,
      total_pending: billing_cycle.total_pending,
      amount_remaining: billing_cycle.amount_remaining,
      expected_payment_per_member: billing_cycle.expected_payment_per_member,
      payment_status: billing_cycle.payment_status,
      overdue: billing_cycle.overdue?,
      days_until_due: billing_cycle.days_until_due,
      can_pay: billing_cycle.user_payment_pending?(Current.user)
    }
  end

  def detailed_billing_cycle_props(billing_cycle)
    billing_cycle_props(billing_cycle).merge(
      members_who_paid: billing_cycle.members_who_paid.map { |user| user_props(user) },
      members_who_havent_paid: billing_cycle.members_who_havent_paid.map { |user| user_props(user) }
    )
  end

  def payment_props(payment)
    {
      id: payment.id,
      amount: payment.amount,
      status: payment.status,
      transaction_id: payment.transaction_id,
      notes: payment.notes,
      created_at: payment.created_at,
      confirmation_date: payment.confirmation_date,
      user: payment.user ? {
        id: payment.user.id,
        email_address: payment.user.email_address,
        name: payment.user.full_name
      } : nil,
      expected_amount: payment.expected_amount,
      overpaid: payment.overpaid?,
      underpaid: payment.underpaid?
    }
  end

  def user_props(user)
    {
      id: user.id,
      email_address: user.email_address
    }
  end

  def billing_cycle_stats
    all_cycles = @project.billing_cycles
    active_cycles = all_cycles.active
    archived_cycles = all_cycles.archived

    # Pre-fetch payments to avoid N+1 queries
    active_cycles_with_payments = active_cycles.includes(:payments)
    all_cycles_with_payments = all_cycles.includes(:payments)

    {
      total: all_cycles.count,
      active: active_cycles.count,
      archived: archived_cycles.count,
      upcoming: active_cycles.upcoming.count,
      overdue: active_cycles.overdue.count,
      due_soon: BillingCycle.due_soon.where(id: active_cycles.pluck(:id)).count,
      fully_paid: active_cycles_with_payments.select(&:fully_paid?).count,
      partially_paid: active_cycles_with_payments.select(&:partially_paid?).count,
      unpaid: active_cycles_with_payments.select(&:unpaid?).count,
      adjusted: all_cycles_with_payments.select(&:adjusted?).count,
      archivable: all_cycles_with_payments.select(&:archivable?).count,
      total_amount: active_cycles.sum(:total_amount),
      total_paid: active_cycles_with_payments.sum(&:total_paid),
      total_remaining: active_cycles_with_payments.sum(&:amount_remaining)
    }
  end

  def cycle_payment_stats(billing_cycle)
    payments = billing_cycle.payments
    {
      total: payments.count,
      pending: payments.pending.count,
      confirmed: payments.confirmed.count,
      rejected: payments.rejected.count,
      with_evidence: payments.with_evidence.count,
      without_evidence: payments.without_evidence.count
    }
  end
end
