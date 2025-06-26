class AddCurrencySupport < ActiveRecord::Migration[7.0]
  def change
    # Add currency support to projects table
    add_column :projects, :currency, :string, null: false, default: 'USD'
    add_index :projects, :currency

    # Add preferred currency to users table
    add_column :users, :preferred_currency, :string, null: false, default: 'USD'
    add_index :users, :preferred_currency

    # Add check constraints for valid ISO 4217 currency codes
    valid_currencies = [
      'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CHF', 'CNY', 'INR', 'BRL',
      'MXN', 'KRW', 'SGD', 'HKD', 'NZD', 'SEK', 'NOK', 'DKK', 'PLN', 'CZK',
      'HUF', 'BGN', 'RON', 'HRK', 'RUB', 'TRY', 'ZAR', 'THB', 'MYR', 'IDR',
      'PHP', 'VND'
    ].map { |code| "'#{code}'" }.join(', ')

    add_check_constraint :projects, "currency IN (#{valid_currencies})", name: 'projects_currency_valid'
    add_check_constraint :users, "preferred_currency IN (#{valid_currencies})", name: 'users_preferred_currency_valid'
  end
end
