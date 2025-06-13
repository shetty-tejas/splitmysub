class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name
      t.decimal :cost
      t.string :billing_cycle
      t.date :renewal_date
      t.text :payment_instructions
      t.integer :reminder_days
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
