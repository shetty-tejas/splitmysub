class MagicLink < ApplicationRecord
  belongs_to :user

  # Validations
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  # Ensure expires_at is in the future when created
  validate :expires_at_must_be_future, on: :create

  # Generate secure token before validation
  before_validation :generate_secure_token, on: :create

  # Scopes for common queries
  scope :active, -> { where(used: false).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :used, -> { where(used: true) }
  scope :unused, -> { where(used: false) }
  scope :for_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }

  # Business logic methods
  def active?
    !used? && !expired?
  end

  def expired?
    expires_at <= Time.current
  end

  def used?
    !!used
  end

  def valid_for_use?
    active?
  end

  def use!
    return false unless valid_for_use?
    update!(used: true)
  end

  def time_until_expiry
    return 0 if expired?
    ((expires_at - Time.current) / 1.hour).round(2)
  end

  def hours_until_expiry
    time_until_expiry
  end

  def self.find_valid_token(token)
    active.find_by(token: token)
  end

  def self.cleanup_expired
    expired.delete_all
  end

  def self.cleanup_used
    used.where("created_at < ?", 24.hours.ago).delete_all
  end

  def self.generate_for_user(user, expires_in: 24.hours)
    create!(
      user: user,
      expires_at: expires_in.from_now
    )
  end

  private

  def generate_secure_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def expires_at_must_be_future
    if expires_at && expires_at <= Time.current
      errors.add(:expires_at, "must be in the future")
    end
  end
end
