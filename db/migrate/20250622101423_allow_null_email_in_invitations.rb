class AllowNullEmailInInvitations < ActiveRecord::Migration[8.0]
  def change
    change_column_null :invitations, :email, true

    # Also need to remove the unique index on project_id + email since null emails can't be unique
    remove_index :invitations, [ :project_id, :email ]

    # Add a partial unique index that only applies to non-null emails
    add_index :invitations, [ :project_id, :email ], unique: true, where: "email IS NOT NULL"
  end
end
