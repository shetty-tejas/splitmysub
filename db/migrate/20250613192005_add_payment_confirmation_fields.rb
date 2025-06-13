class AddPaymentConfirmationFields < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :confirmation_notes, :text
    add_column :payments, :confirmed_by_id, :bigint
    add_column :payments, :disputed, :boolean, default: false
    add_column :payments, :dispute_reason, :text
    add_column :payments, :dispute_resolved_at, :datetime
    add_column :payments, :status_history, :json, default: []

    add_foreign_key :payments, :users, column: :confirmed_by_id
    add_index :payments, :confirmed_by_id
    add_index :payments, :disputed
  end
end
