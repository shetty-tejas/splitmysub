class AddTransactionIdAndNotesToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :transaction_id, :string
    add_column :payments, :notes, :text
  end
end
