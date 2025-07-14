class TelegramMessage < ApplicationRecord
  belongs_to :user

  # Message types
  TYPES = %w[
    payment_reminder
    billing_cycle_notification
    payment_confirmation
    project_invitation
    account_link_verification
    bot_command_response
  ].freeze

  # Message statuses
  STATUSES = %w[pending sent delivered failed].freeze

  validates :message_type, presence: true, inclusion: { in: TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :content, presence: true

  scope :by_type, ->(type) { where(message_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: "pending") }
  scope :sent, -> { where(status: "sent") }
  scope :failed, -> { where(status: "failed") }
  scope :for_user, ->(user) { where(user: user) }

  def sent?
    status == "sent"
  end

  def delivered?
    status == "delivered"
  end

  def failed?
    status == "failed"
  end
end
