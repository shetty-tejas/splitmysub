class PaymentsController < ApplicationController
  before_action :set_payment, only: [ :show, :update, :destroy ]
  before_action :set_billing_cycle, only: [ :new, :create ]
  before_action :authorize_payment_access, only: [ :show ]
  before_action :authorize_payment_modification, only: [ :update, :destroy ]

  def index
    # Check if this is a project-specific payment view
    if params[:project_id].present?
      @project = Project.find_by!(slug: params[:project_id])
      ensure_project_access!(@project)

      # Get all payments for this project's billing cycles
      @payments = Payment.joins(billing_cycle: :project)
                        .where(billing_cycles: { project_id: @project.id })
                        .includes(:user, :billing_cycle, :evidence_attachment)
                        .order(created_at: :desc)

      render inertia: "payments/ProjectIndex", props: {
        project: project_props(@project),
        payments: @payments.map { |payment| payment_props(payment) },
        user_permissions: {
          is_owner: @project.is_owner?(Current.user),
          is_member: @project.is_member?(Current.user),
          can_manage: @project.is_owner?(Current.user)
        }
      }
    else
      # Original behavior - show user's own payments
      @payments = Current.user.payments.includes(:billing_cycle, :evidence_attachment)
                             .order(created_at: :desc)

      render inertia: "payments/Index", props: {
        payments: @payments.map { |payment| payment_props(payment) }
      }
    end
  end

  def show
    render inertia: "payments/Show", props: {
      payment: payment_props(@payment),
      billing_cycle: billing_cycle_props(@payment.billing_cycle),
      project: project_props(@payment.project)
    }
  end

  def new
    @payment = @billing_cycle.payments.build(user: Current.user, status: "pending")

    render inertia: "payments/New", props: {
      payment: payment_props(@payment),
      billing_cycle: billing_cycle_props(@billing_cycle),
      project: project_props(@billing_cycle.project)
    }
  end

  def create
    @payment = @billing_cycle.payments.build(payment_params.merge(user: Current.user, status: "pending"))

    if @payment.save
      redirect_to @payment, notice: "Payment evidence submitted successfully!"
    else
      render inertia: "payments/New", props: {
        payment: payment_props(@payment),
        billing_cycle: billing_cycle_props(@billing_cycle),
        project: project_props(@billing_cycle.project),
        errors: @payment.errors.full_messages
      }
    end
  end

  def update
    if @payment.update(payment_params)
      redirect_to @payment, notice: "Payment updated successfully!"
    else
      render inertia: "payments/Show", props: {
        payment: payment_props(@payment),
        billing_cycle: billing_cycle_props(@payment.billing_cycle),
        project: project_props(@payment.project),
        errors: @payment.errors.full_messages
      }
    end
  end

  def destroy
    @payment.destroy
    redirect_to payments_path, notice: "Payment evidence deleted successfully!"
  end



  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def set_billing_cycle
    @billing_cycle = BillingCycle.find(params[:billing_cycle_id])
  end

  def authorize_payment_access
    ensure_payment_access!(@payment)
  end

  def authorize_payment_modification
    authorize!(:update, @payment) if action_name == "update"
    authorize!(:destroy, @payment) if action_name == "destroy"
  end

  def payment_params
    params.require(:payment).permit(:amount, :transaction_id, :notes, :evidence)
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

  def billing_cycle_props(billing_cycle)
    {
      id: billing_cycle.id,
      cycle_month: billing_cycle.cycle_month,
      cycle_year: billing_cycle.cycle_year,
      total_amount: billing_cycle.total_amount,
      due_date: billing_cycle.due_date,
      total_paid: billing_cycle.total_paid,
      amount_remaining: billing_cycle.amount_remaining,
      expected_payment_per_member: billing_cycle.expected_payment_per_member,
      payment_status: billing_cycle.payment_status,
      overdue: billing_cycle.overdue?,
      days_until_due: billing_cycle.days_until_due
    }
  end

  def project_props(project)
    {
      id: project.id,
      slug: project.slug,
      name: project.name,
      description: project.description,
      currency: project.currency
    }
  end
end
