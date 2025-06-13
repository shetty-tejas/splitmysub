class AddArchivingAndAdjustmentsToBillingCycles < ActiveRecord::Migration[8.0]
  def change
    add_column :billing_cycles, :archived, :boolean, default: false, null: false
    add_column :billing_cycles, :archived_at, :datetime
    add_column :billing_cycles, :adjustment_reason, :text
    add_column :billing_cycles, :adjusted_at, :datetime
    add_column :billing_cycles, :original_amount, :decimal
    add_column :billing_cycles, :original_due_date, :date

    # Add indexes for performance
    add_index :billing_cycles, :archived
    add_index :billing_cycles, :archived_at
    add_index :billing_cycles, :adjusted_at
  end
end
