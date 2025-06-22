class Invitation < ApplicationRecord
  belongs_to :project
  belongs_to :invited_by, class_name: "User"

  # Validations
  validates :email, format: {
    with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/,
    message: "must be a valid email address with a proper domain"
  }, allow_blank: true
  validates :token, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: {
    in: %w[pending accepted declined expired],
    message: "%{value} is not a valid status"
  }
  validates :role, presence: true, inclusion: {
    in: %w[member],
    message: "%{value} is not a valid role"
  }
  validates :expires_at, presence: true
  validates :email, uniqueness: { scope: :project_id, message: "has already been invited to this project" }, allow_blank: true

  # Prevent inviting existing members or owner
  validate :email_not_already_member
  validate :email_not_project_owner
  validate :expires_at_in_future

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :declined, -> { where(status: "declined") }
  scope :expired, -> { where(status: "expired") }
  scope :active, -> { where(status: "pending").where("expires_at > ?", Time.current) }
  scope :for_project, ->(project) { where(project: project) }
  scope :for_email, ->(email) { where(email: email) }

  # Callbacks
  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  # Business logic methods
  def expired?
    expires_at < Time.current || status == "expired"
  end

  def active?
    status == "pending" && !expired?
  end

  def can_accept?
    active?
  end

  def accept!(user)
    return false unless can_accept?
    return false unless user.present?

    transaction do
      # Create project membership
      project.project_memberships.create!(
        user: user,
        role: role
      )

      # Update invitation status and expire the token (skip validations to avoid email_not_already_member check)
      update_columns(status: "accepted", expires_at: Time.current)
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def decline!
    return false unless can_accept?
    # Update status and expire the token immediately (skip validations)
    update_columns(status: "declined", expires_at: Time.current)
    true
  end

  def expire!
    update(status: "expired") if status == "pending"
  end

  # Class methods
  def self.expire_old_invitations!
    pending.where("expires_at < ?", Time.current).update_all(status: "expired")
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32) if token.blank?
  end

  def set_expiration
    self.expires_at = 7.days.from_now if expires_at.blank?
  end

  def email_not_already_member
    return unless project && email.present?

    if project.project_memberships.joins(:user).exists?(users: { email_address: email })
      errors.add(:email, "is already a member of this project")
    end
  end

  def email_not_project_owner
    return unless project && email.present?

    if project.user.email_address == email
      errors.add(:email, "cannot invite the project owner")
    end
  end

  def expires_at_in_future
    return unless expires_at.present?

    if expires_at <= Time.current
      errors.add(:expires_at, "must be in the future")
    end
  end
end
