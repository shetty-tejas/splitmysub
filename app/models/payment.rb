class Payment < ApplicationRecord
  include CurrencySupport

  belongs_to :billing_cycle
  belongs_to :user
  belongs_to :confirmed_by, class_name: "User", optional: true
  has_many_attached :evidence_files

  # ActiveStorage for payment evidence
  has_one_attached :evidence

  # File validations for evidence
  validate :evidence_validation, if: -> { evidence.attached? }

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: {
    in: %w[pending confirmed disputed rejected],
    message: "%{value} is not a valid status"
  }
  validates :user_id, uniqueness: {
    scope: :billing_cycle_id,
    message: "has already made a payment for this billing cycle"
  }
  validates :transaction_id, uniqueness: { scope: :billing_cycle_id }, allow_blank: true

  # Validate confirmation_date is present when status is confirmed
  validates :confirmation_date, presence: true, if: :confirmed?

  # Validate amount doesn't exceed expected amount
  validate :amount_within_expected_range

  # Callbacks
  after_update :send_confirmation_email, if: :saved_change_to_status?
  after_update :track_status_change, if: :saved_change_to_status?

  # Scopes for common queries
  scope :pending, -> { where(status: "pending") }
  scope :confirmed, -> { where(status: "confirmed") }
  scope :disputed, -> { where(disputed: true) }
  scope :rejected, -> { where(status: "rejected") }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_billing_cycle, ->(cycle) { where(billing_cycle: cycle) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_evidence, -> { joins(:evidence_attachment) }
  scope :without_evidence, -> { left_joins(:evidence_attachment).where(active_storage_attachments: { id: nil }) }
  scope :by_status, ->(status) { where(status: status) }
  scope :for_project, ->(project) { joins(:billing_cycle).where(billing_cycles: { project: project }) }

  # Business logic methods
  def pending?
    status == "pending"
  end

  def confirmed?
    status == "confirmed"
  end

  def disputed?
    disputed
  end

  def rejected?
    status == "rejected"
  end

  def has_evidence?
    evidence.attached?
  end

  def confirm!(confirmed_by_user = nil, notes = nil)
    update!(
      status: "confirmed",
      confirmation_date: Date.current,
      confirmed_by: confirmed_by_user,
      confirmation_notes: notes
    )
  end

  def reject!(confirmed_by_user = nil, notes = nil)
    update!(
      status: "rejected",
      confirmation_date: nil,
      confirmed_by: confirmed_by_user,
      confirmation_notes: notes
    )
  end

  def dispute!(reason, disputed_by_user = nil)
    update!(
      disputed: true,
      dispute_reason: reason,
      confirmed_by: disputed_by_user
    )
  end

  def resolve_dispute!(resolved_by_user = nil)
    update!(
      disputed: false,
      dispute_resolved_at: Time.current,
      confirmed_by: resolved_by_user
    )
  end

  def add_note!(note, added_by_user = nil)
    current_notes = confirmation_notes || ""
    timestamp = Time.current.strftime("%Y-%m-%d %H:%M")
    user_info = added_by_user ? " (#{added_by_user.email_address})" : ""
    new_note = "[#{timestamp}#{user_info}] #{note}"

    updated_notes = current_notes.blank? ? new_note : "#{current_notes}\n\n#{new_note}"
    update!(confirmation_notes: updated_notes)
  end

  def currency
    billing_cycle.currency
  end

  def format_currency(amount)
    billing_cycle.project.format_amount(amount)
  end

  def format_amount
    format_currency(amount)
  end

  def expected_amount
    billing_cycle.expected_payment_per_member
  end

  def format_expected_amount
    format_currency(expected_amount)
  end

  def overpaid?
    return false unless amount

    amount > expected_amount
  end

  def underpaid?
    return false unless amount

    amount < expected_amount
  end

  def correct_amount?
    return false unless amount

    amount == expected_amount
  end

  def project
    billing_cycle.project
  end

  def overdue?
    billing_cycle.overdue? && status != "confirmed"
  end

  def days_until_due
    billing_cycle.days_until_due
  end

  def payment_type
    if overpaid?
      "overpayment"
    elsif underpaid?
      "partial"
    else
      "full"
    end
  end

  def days_since_payment
    return 0 unless confirmation_date
    (Date.current - confirmation_date).to_i
  end

  def can_be_confirmed_by?(user)
    project.is_owner?(user)
  end

  def status_changes
    status_history || []
  end

  def last_status_change
    status_changes.last
  end

  def evidence_filename
    evidence.filename.to_s if has_evidence?
  end

  def evidence_url
    evidence.url if has_evidence?
  end

  def status_changed?
    status_changed_from_pending_to_confirmed? || status_changed_from_pending_to_disputed?
  end

  private

  def evidence_validation
    return unless evidence.attached?

    # Validate file type
    allowed_types = %w[image/png image/jpg image/jpeg image/heic application/pdf]
    unless allowed_types.include?(evidence.content_type)
      errors.add(:evidence, "must be a PNG, JPG, HEIC, or PDF file")
    end

    # Validate file size (5MB limit)
    if evidence.byte_size > 5.megabytes
      errors.add(:evidence, "must be less than 5MB")
    end
  end

  def amount_within_expected_range
    return unless billing_cycle && amount

    expected = expected_amount
    if amount > expected * 2 # Allow up to 2x expected (for covering others)
      errors.add(:amount, "cannot exceed #{expected * 2} (2x the expected amount)")
    end
  end

  def send_confirmation_email
    return unless confirmed?

    # Send confirmation email asynchronously
    PaymentConfirmationJob.perform_later(id)
  end

  def track_status_change
    return unless status.present? && saved_change_to_status?

    change_record = {
      from_status: saved_change_to_status[0],
      to_status: saved_change_to_status[1],
      changed_at: Time.current.iso8601,
      changed_by: confirmed_by&.email_address
    }

    current_history = status_history || []
    # Use update_column to avoid triggering callbacks again
    update_column(:status_history, current_history + [ change_record ])
  end





  def status_changed_from_pending_to_confirmed?
    status_was == "pending" && status == "confirmed"
  end

  def status_changed_from_pending_to_disputed?
    status_was == "pending" && status == "disputed"
  end
end
