class ProjectMembership < ApplicationRecord
  belongs_to :user
  belongs_to :project, counter_cache: :memberships_count

  # Validations
  validates :user_id, uniqueness: { scope: :project_id, message: "is already a member of this project" }
  validates :role, presence: true, inclusion: {
    in: %w[member],
    message: "%{value} is not a valid role"
  }

  # Prevent owner from being added as member
  validate :user_cannot_be_project_owner

  # Scopes for common queries
  scope :members, -> { where(role: "member") }
  scope :for_project, ->(project) { where(project: project) }
  scope :for_user, ->(user) { where(user: user) }

  # Business logic methods
  def member?
    role == "member"
  end

  # Only project owners can manage projects and invite members
  # Members have read access only
  def can_manage_project?
    false
  end

  def can_invite_members?
    false
  end

  private

  def user_cannot_be_project_owner
    if project && user && project.user == user
      errors.add(:user, "cannot be added as member - already the project owner")
    end
  end
end
