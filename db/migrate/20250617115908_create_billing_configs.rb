class CreateBillingConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_configs do |t|
      t.integer :generation_months_ahead, null: false, default: 3
      t.integer :archiving_months_threshold, null: false, default: 6
      t.integer :due_soon_days, null: false, default: 7
      t.boolean :auto_archiving_enabled, null: false, default: true
      t.boolean :auto_generation_enabled, null: false, default: true
      t.text :default_billing_frequencies, default: '["monthly"]'
      t.text :supported_billing_frequencies, default: '["monthly", "quarterly", "yearly"]'
      t.text :reminder_schedule, default: '[7, 3, 1]'
      t.integer :payment_grace_period_days, null: false, default: 5

      # Reminder fields for policy objects
      t.boolean :reminders_enabled, null: false, default: true
      t.integer :gentle_reminder_days_before, null: false, default: 3
      t.integer :standard_reminder_days_overdue, null: false, default: 1
      t.integer :urgent_reminder_days_overdue, null: false, default: 7
      t.integer :final_notice_days_overdue, null: false, default: 14
      t.string :default_frequency, null: false, default: 'monthly'

      t.timestamps
    end

    # Add constraints to ensure valid values
    add_check_constraint :billing_configs, "generation_months_ahead > 0 AND generation_months_ahead <= 12", name: "generation_months_ahead_range"
    add_check_constraint :billing_configs, "archiving_months_threshold > 0 AND archiving_months_threshold <= 24", name: "archiving_months_threshold_range"
    add_check_constraint :billing_configs, "due_soon_days > 0 AND due_soon_days <= 30", name: "due_soon_days_range"
    add_check_constraint :billing_configs, "payment_grace_period_days >= 0 AND payment_grace_period_days <= 30", name: "payment_grace_period_range"

    # Reminder field constraints
    add_check_constraint :billing_configs, "gentle_reminder_days_before > 0 AND gentle_reminder_days_before <= 30", name: "gentle_reminder_days_range"
    add_check_constraint :billing_configs, "standard_reminder_days_overdue >= 0 AND standard_reminder_days_overdue <= 30", name: "standard_reminder_days_range"
    add_check_constraint :billing_configs, "urgent_reminder_days_overdue >= 0 AND urgent_reminder_days_overdue <= 60", name: "urgent_reminder_days_range"
    add_check_constraint :billing_configs, "final_notice_days_overdue >= 0 AND final_notice_days_overdue <= 90", name: "final_notice_days_range"
    add_check_constraint :billing_configs, "default_frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')", name: "default_frequency_valid"

    # Create the default configuration record
    reversible do |dir|
      dir.up do
        BillingConfig.create!(
          generation_months_ahead: 3,
          archiving_months_threshold: 6,
          due_soon_days: 7,
          auto_archiving_enabled: true,
          auto_generation_enabled: true,
          default_billing_frequencies: '["monthly"]',
          supported_billing_frequencies: '["monthly", "quarterly", "yearly"]',
          reminder_schedule: '[7, 3, 1]',
          payment_grace_period_days: 5,
          reminders_enabled: true,
          gentle_reminder_days_before: 3,
          standard_reminder_days_overdue: 1,
          urgent_reminder_days_overdue: 7,
          final_notice_days_overdue: 14,
          default_frequency: 'monthly'
        )
      end
    end
  end
end
