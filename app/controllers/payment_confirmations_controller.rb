class PaymentConfirmationsController < ApplicationController
  before_action :set_project
  before_action :ensure_project_creator_or_admin
  before_action :set_payment, only: [ :show, :update, :add_note ]

  def index
    @payments = @project.payments
                       .includes(:user, :billing_cycle, :confirmed_by, :evidence_attachment)
                       .order(created_at: :desc)

    # Apply filters
    @payments = @payments.where(status: params[:status]) if params[:status].present?
    @payments = @payments.where(disputed: true) if params[:disputed] == "true"

    # Apply search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @payments = @payments.joins(:user)
                          .where("users.email_address ILIKE ? OR payments.transaction_id ILIKE ? OR payments.confirmation_notes ILIKE ?",
                                search_term, search_term, search_term)
    end

    # Apply sorting
    case params[:sort]
    when "amount_asc"
      @payments = @payments.order(amount: :asc)
    when "amount_desc"
      @payments = @payments.order(amount: :desc)
    when "date_asc"
      @payments = @payments.order(created_at: :asc)
    when "date_desc"
      @payments = @payments.order(created_at: :desc)
    when "status"
      @payments = @payments.order(:status)
    else
      @payments = @payments.order(created_at: :desc)
    end

    render inertia: "payment_confirmations/Index", props: {
      project: project_props(@project),
      payments: @payments.map { |payment| payment_confirmation_props(payment) },
      filters: {
        status: params[:status],
        disputed: params[:disputed],
        search: params[:search],
        sort: params[:sort]
      },
      stats: payment_stats
    }
  end

  def show
    render inertia: "payment_confirmations/Show", props: {
      project: project_props(@project),
      payment: detailed_payment_props(@payment),
      billing_cycle: billing_cycle_props(@payment.billing_cycle)
    }
  end

  def update
    case params[:action_type]
    when "confirm"
      if @payment.confirm!(Current.user, params[:notes])
        redirect_to project_payment_confirmation_path(@project, @payment),
                   notice: "Payment confirmed successfully!"
      else
        redirect_back(fallback_location: project_payment_confirmations_path(@project),
                     alert: @payment.errors.full_messages.join(", "))
      end
    when "reject"
      if @payment.reject!(Current.user, params[:notes])
        redirect_to project_payment_confirmation_path(@project, @payment),
                   notice: "Payment rejected."
      else
        redirect_back(fallback_location: project_payment_confirmations_path(@project),
                     alert: @payment.errors.full_messages.join(", "))
      end
    when "dispute"
      if @payment.dispute!(params[:dispute_reason], Current.user)
        redirect_to project_payment_confirmation_path(@project, @payment),
                   notice: "Payment marked as disputed."
      else
        redirect_back(fallback_location: project_payment_confirmations_path(@project),
                     alert: @payment.errors.full_messages.join(", "))
      end
    when "resolve_dispute"
      if @payment.resolve_dispute!(Current.user)
        redirect_to project_payment_confirmation_path(@project, @payment),
                   notice: "Dispute resolved."
      else
        redirect_back(fallback_location: project_payment_confirmations_path(@project),
                     alert: @payment.errors.full_messages.join(", "))
      end
    else
      redirect_back(fallback_location: project_payment_confirmations_path(@project),
                   alert: "Invalid action.")
    end
  end

  def batch_update
    payment_ids = params[:payment_ids] || []
    action_type = params[:action_type]
    notes = params[:notes]

    if payment_ids.empty?
      redirect_back(fallback_location: project_payment_confirmations_path(@project),
                   alert: "No payments selected.")
      return
    end

    payments = @project.payments.where(id: payment_ids)
    success_count = 0
    error_count = 0

    payments.each do |payment|
      case action_type
      when "confirm"
        if payment.confirm!(Current.user, notes)
          success_count += 1
        else
          error_count += 1
        end
      when "reject"
        if payment.reject!(Current.user, notes)
          success_count += 1
        else
          error_count += 1
        end
      end
    end

    if success_count > 0
      redirect_to project_payment_confirmations_path(@project),
                 notice: "#{success_count} payment(s) updated successfully."
    else
      redirect_to project_payment_confirmations_path(@project),
                 alert: "Failed to update payments."
    end
  end

  def add_note
    if @payment.add_note!(params[:note], Current.user)
      redirect_to project_payment_confirmation_path(@project, @payment),
                 notice: "Note added successfully."
    else
      redirect_back(fallback_location: project_payment_confirmation_path(@project, @payment),
                   alert: "Failed to add note.")
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to projects_path, alert: "Project not found."
  end

  def set_payment
    @payment = @project.payments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to project_payment_confirmations_path(@project), alert: "Payment not found."
  end

  def ensure_project_creator_or_admin
    unless @project.is_owner?(Current.user) ||
           @project.project_memberships.where(user: Current.user, role: "admin").exists?
      redirect_to project_path(@project),
                 alert: "You don't have permission to manage payment confirmations."
    end
  end

  def project_props(project)
    {
      id: project.id,
      name: project.name,
      description: project.description,
      cost: project.cost,
      cost_per_member: project.cost_per_member,
      is_owner: project.is_owner?(Current.user)
    }
  end

  def payment_confirmation_props(payment)
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
      evidence_url: payment.evidence.attached? ? rails_blob_path(payment.evidence) : nil,
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
      } : nil,
      billing_cycle: {
        id: payment.billing_cycle.id,
        due_date: payment.billing_cycle.due_date,
        total_amount: payment.billing_cycle.total_amount
      }
    }
  end

  def detailed_payment_props(payment)
    payment_confirmation_props(payment).merge(
      status_history: payment.status_changes,
      dispute_resolved_at: payment.dispute_resolved_at,
      expected_amount: payment.expected_amount,
      overpaid: payment.overpaid?,
      underpaid: payment.underpaid?,
      exact_amount: payment.exact_amount?
    )
  end

  def billing_cycle_props(billing_cycle)
    {
      id: billing_cycle.id,
      due_date: billing_cycle.due_date,
      total_amount: billing_cycle.total_amount,
      expected_payment_per_member: billing_cycle.expected_payment_per_member,
      total_paid: billing_cycle.total_paid,
      amount_remaining: billing_cycle.amount_remaining,
      fully_paid: billing_cycle.fully_paid?
    }
  end

  def payment_stats
    all_payments = @project.payments
    {
      total: all_payments.count,
      pending: all_payments.pending.count,
      confirmed: all_payments.confirmed.count,
      rejected: all_payments.rejected.count,
      disputed: all_payments.disputed.count,
      with_evidence: all_payments.with_evidence.count,
      without_evidence: all_payments.without_evidence.count
    }
  end
end
