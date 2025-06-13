class CreateBillingCycles < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_cycles do |t|
      t.references :project, null: false, foreign_key: true
      t.date :due_date
      t.decimal :total_amount

      t.timestamps
    end
  end
end
