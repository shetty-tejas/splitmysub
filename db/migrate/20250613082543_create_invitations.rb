class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :project, null: false, foreign_key: true
      t.string :email, null: false
      t.string :token, null: false
      t.string :status, null: false, default: 'pending'
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :role, null: false, default: 'member'
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email
    add_index :invitations, [ :project_id, :email ], unique: true
    add_index :invitations, :status
    add_index :invitations, :expires_at
  end
end
