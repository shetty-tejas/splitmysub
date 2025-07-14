class AddTelegramToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :telegram_user_id, :string
    add_column :users, :telegram_username, :string
    add_column :users, :telegram_notifications_enabled, :boolean, default: true
    add_column :users, :telegram_verification_token, :string
    add_column :users, :telegram_verification_token_expires_at, :datetime

    add_index :users, :telegram_user_id, unique: true
    add_index :users, :telegram_verification_token, unique: true
  end
end
