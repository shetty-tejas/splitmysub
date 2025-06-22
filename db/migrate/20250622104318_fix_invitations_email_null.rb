class FixInvitationsEmailNull < ActiveRecord::Migration[8.0]
  def up
    # Create a new table with the correct structure
    create_table :invitations_new do |t|
      t.references :project, null: false, foreign_key: true
      t.string :email, null: true  # Allow null emails
      t.string :token, null: false
      t.string :status, null: false, default: 'pending'
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :role, null: false, default: 'member'
      t.datetime :expires_at, null: false

      t.timestamps
    end

    # Copy data from old table to new table
    execute <<-SQL
      INSERT INTO invitations_new (
        project_id, email, token, status, invited_by_id, role, expires_at, created_at, updated_at
      )
      SELECT#{' '}
        project_id, email, token, status, invited_by_id, role, expires_at, created_at, updated_at
      FROM invitations
    SQL

    # Drop the old table and rename the new one
    drop_table :invitations
    rename_table :invitations_new, :invitations

    # Add indexes
    add_index :invitations, :token, unique: true
    add_index :invitations, :email
    add_index :invitations, [ :project_id, :email ], unique: true, where: "email IS NOT NULL"
    add_index :invitations, :status
    add_index :invitations, :expires_at
  end

  def down
    # Create the old table structure
    create_table :invitations_old do |t|
      t.references :project, null: false, foreign_key: true
      t.string :email, null: false  # Back to not null
      t.string :token, null: false
      t.string :status, null: false, default: 'pending'
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :role, null: false, default: 'member'
      t.datetime :expires_at, null: false

      t.timestamps
    end

    # Copy data back (excluding null emails)
    execute <<-SQL
      INSERT INTO invitations_old (
        project_id, email, token, status, invited_by_id, role, expires_at, created_at, updated_at
      )
      SELECT#{' '}
        project_id, email, token, status, invited_by_id, role, expires_at, created_at, updated_at
      FROM invitations
      WHERE email IS NOT NULL
    SQL

    # Drop the current table and rename the old one
    drop_table :invitations
    rename_table :invitations_old, :invitations

    # Add original indexes
    add_index :invitations, :token, unique: true
    add_index :invitations, :email
    add_index :invitations, [ :project_id, :email ], unique: true
    add_index :invitations, :status
    add_index :invitations, :expires_at
  end
end
