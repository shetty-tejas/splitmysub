class AddIndexesForPerformance < ActiveRecord::Migration[8.0]
  def change
    # Add composite indexes for common query patterns
    add_index :billing_cycles, [ :project_id, :due_date ], name: 'index_billing_cycles_on_project_and_due_date'
    add_index :payments, [ :billing_cycle_id, :user_id ], name: 'index_payments_on_billing_cycle_and_user'
    add_index :project_memberships, [ :project_id, :user_id ], name: 'index_project_memberships_on_project_and_user'
    add_index :billing_cycles, [ :due_date, :status ], name: 'index_billing_cycles_on_due_date_and_status'
    add_index :payments, [ :user_id, :created_at ], name: 'index_payments_on_user_and_created_at'
    add_index :projects, [ :user_id, :created_at ], name: 'index_projects_on_user_and_created_at'
  end
end
