class FixUsersTable < ActiveRecord::Migration[8.0]
  def change
    # Rename email to email_address to match the model
    rename_column :users, :email, :email_address

    # Add password_digest for has_secure_password
    add_column :users, :password_digest, :string

    # Add first_name and last_name columns
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string

    # Update the index to use the new column name
    remove_index :users, :email if index_exists?(:users, :email)
    add_index :users, :email_address, unique: true unless index_exists?(:users, :email_address)
  end
end
