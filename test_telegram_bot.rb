#!/usr/bin/env ruby

require 'bundler/setup'

# Skip if telegram-bot-ruby gem is not available
begin
  require 'telegram/bot'
rescue LoadError
  puts "Telegram bot gem not available - skipping test"
  return
end

# Load Rails environment
require_relative 'config/environment'

token = Rails.application.credentials.telegram_bot_token
puts "Token present: #{token.present?}"

if token.present?
  bot = Telegram::Bot::Client.new(token)

  begin
    result = bot.api.get_me
    puts "✅ Bot connected successfully!"
    puts "Bot result: #{result.inspect}"

    # Test processing a start command
    service = TelegramBotService.new
    puts "✅ TelegramBotService initialized"

    # Check if we can find a user with the token you tried
    user = User.find_by(telegram_verification_token: '862b062aff74544ed3decb5cc8a4a717')
    if user
      puts "✅ Found user with token: #{user.email_address}"
      puts "Token expires at: #{user.telegram_verification_token_expires_at}"
      puts "Token valid: #{user.telegram_verification_token_valid?}"
    else
      puts "❌ No user found with that token"
    end

  rescue => e
    puts "❌ Error: #{e.message}"
  end
else
  puts "❌ No token configured"
end
