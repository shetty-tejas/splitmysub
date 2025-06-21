class ConsolidateRolesToOwnerAndMember < ActiveRecord::Migration[8.0]
  def up
    # Convert all admin roles to member roles in project_memberships
    execute "UPDATE project_memberships SET role = 'member' WHERE role = 'admin'"

    # Convert all admin roles to member roles in invitations
    execute "UPDATE invitations SET role = 'member' WHERE role = 'admin'"

    # Add a note about the consolidation
    puts "Consolidated roles: All admin roles have been converted to member roles"
    puts "The system now only supports 'owner' (implicit) and 'member' roles"
  end

  def down
    # This migration is not easily reversible since we don't know which members
    # were originally admins. We'll add a warning message.
    puts "WARNING: This migration cannot be automatically reversed."
    puts "All project memberships and invitations now use 'member' role."
    puts "You would need to manually update specific users back to 'admin' role if needed."
  end
end
