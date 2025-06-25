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
      transaction_id: payment.transaction_id,
      notes: payment.notes,
      status: payment.status,
      disputed: payment.disputed?,
      dispute_reason: payment.dispute_reason,
      confirmation_date: payment.confirmation_date,
      confirmation_notes: payment.confirmation_notes,
      created_at: payment.created_at,
      updated_at: payment.updated_at,
      has_evidence: payment.has_evidence?,
      evidence_url: payment.evidence.attached? ? secure_payment_evidence_path(payment) : nil,
      evidence_filename: payment.evidence.attached? ? payment.evidence.filename.to_s : nil,
      evidence_content_type: payment.evidence.attached? ? payment.evidence.content_type : nil,
      evidence_byte_size: payment.evidence.attached? ? payment.evidence.byte_size : nil,
      user: {
        id: payment.user.id,
        email_address: payment.user.email_address
      },
      confirmed_by: payment.confirmed_by ? {
        id: payment.confirmed_by.id,
        email_address: payment.confirmed_by.email_address
      } : nil
    }
  end

  def billing_cycle_props(billing_cycle)
    {
      id: billing_cycle.id,
      due_date: billing_cycle.due_date,
      total_amount: billing_cycle.total_amount,
      expected_payment_per_member: billing_cycle.project&.cost_per_member || 0
    }
  end

  def project_props(project)
    {
      id: project.id,
      slug: project.slug,
      name: project.name,
      description: project.description
    }
  end
end
