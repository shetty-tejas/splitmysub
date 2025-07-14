class CreateTelegramMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :telegram_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.string :message_type, null: false
      t.string :telegram_message_id
      t.text :content
      t.datetime :sent_at
      t.string :status, default: "pending"

      t.timestamps
    end

    add_index :telegram_messages, :telegram_message_id
    add_index :telegram_messages, :message_type
    add_index :telegram_messages, :status
  end
end
