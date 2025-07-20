#!/usr/bin/env ruby

module TelegramPolling
  def self.start
    # Skip if in test environment
    if Rails.env.test?
      puts "Skipping Telegram integration (test environment)"
      return
    end

    # Skip if telegram-bot-ruby gem is not available
    begin
      require "telegram/bot"
    rescue LoadError
      puts "Telegram bot gem not available - skipping polling"
      return
    end

    puts "Starting Telegram polling..."

    Rails.application.eager_load!

    bot_token = Rails.application.credentials.telegram_bot_token

    unless bot_token
      puts "No Telegram bot token found - skipping polling"
      return
    end

    Telegram::Bot::Client.run(bot_token) do |bot|
      puts "✅ Telegram polling started successfully!"

      bot.listen do |message|
        begin
          telegram_service = TelegramBotService.new
          telegram_service.process_message(message)
        rescue => e
          puts "❌ Error processing Telegram message: #{e.message}"
          puts e.backtrace.join("\n")
        end
      end
    end
  rescue => e
    puts "❌ Error in Telegram polling: #{e.message}"
    puts e.backtrace.join("\n")
  end
end

# Only run if this file is executed directly (not when required)
if __FILE__ == $0
  require_relative "../config/environment"
  TelegramPolling.start
end
