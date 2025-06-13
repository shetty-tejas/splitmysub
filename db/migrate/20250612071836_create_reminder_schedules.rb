class CreateReminderSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :reminder_schedules do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :days_before
      t.integer :escalation_level

      t.timestamps
    end
  end
end
