class PaymentsController < ApplicationController
  before_action :set_payment, only: [ :show, :update, :destroy ]
  before_action :set_billing_cycle, only: [ :new, :create ]
  before_action :ensure_user_can_access_payment, only: [ :show, :update, :destroy ]

  def index
    @payments = Current.user.payments.includes(:billing_cycle, :evidence_attachment)
                           .order(created_at: :desc)

    render inertia: "payments/Index", props: {
      payments: @payments.map { |payment| payment_props(payment) }
    }
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

  def download_evidence
    @payment = Payment.find(params[:id])

    unless can_access_payment?(@payment)
      redirect_to root_path, alert: "You don't have permission to access this payment."
      return
    end

    unless @payment.evidence.attached?
      redirect_back(fallback_location: @payment, alert: "No evidence file attached.")
      return
    end

    redirect_to rails_blob_path(@payment.evidence, disposition: "attachment")
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  end

  def set_billing_cycle
    @billing_cycle = BillingCycle.find(params[:billing_cycle_id])
  end

  def ensure_user_can_access_payment
    unless can_access_payment?(@payment)
      redirect_to root_path, alert: "You don't have permission to access this payment."
    end
  end

  def can_access_payment?(payment)
    # User can access their own payments or if they're a project creator
    payment.user == Current.user || (payment.project&.user == Current.user)
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
      confirmation_date: payment.confirmation_date,
      created_at: payment.created_at,
      updated_at: payment.updated_at,
      has_evidence: payment.has_evidence?,
      evidence_url: payment.evidence.attached? ? rails_blob_path(payment.evidence) : nil,
      evidence_filename: payment.evidence.attached? ? payment.evidence.filename.to_s : nil,
      evidence_content_type: payment.evidence.attached? ? payment.evidence.content_type : nil,
      evidence_byte_size: payment.evidence.attached? ? payment.evidence.byte_size : nil,
      user: {
        id: payment.user.id,
        email_address: payment.user.email_address
      }
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
      name: project.name,
      description: project.description
    }
  end
end
