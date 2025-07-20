#!/usr/bin/env ruby

require "bundler/setup"

# Skip if telegram-bot-ruby gem is not available
begin
  require "telegram/bot"
rescue LoadError
  puts "Telegram bot gem not available - skipping polling"
  return
end

# Load Rails environment
require_relative "../config/environment"

# Setup logging
puts "Starting Telegram bot polling..."
Rails.logger.info "Starting Telegram bot polling..."

token = Rails.application.credentials.telegram_bot_token
if token.blank?
  if Rails.env.test?
    puts "Telegram bot token not found in credentials - skipping in test environment"
    Rails.logger.info "Telegram bot token not found in credentials - skipping in test environment"
    return
  else
    puts "ERROR: Telegram bot token not found in credentials"
    Rails.logger.error "Telegram bot token not found in credentials"
    exit 1
  end
end

puts "Bot: @SplitMySubBot"
Rails.logger.info "Bot: @SplitMySubBot"

# Graceful shutdown handling
Signal.trap("INT") do
  puts "Shutting down Telegram bot polling..."
  exit 0
end

Signal.trap("TERM") do
  puts "Shutting down Telegram bot polling..."
  exit 0
end

begin
  Telegram::Bot::Client.run(token) do |bot|
    bot.listen do |message|
      case message
      when Telegram::Bot::Types::Message
        puts "Received message: #{message.text} from #{message.chat.id}"
        Rails.logger.info "Received message: #{message.text} from #{message.chat.id}"

        # Create a fake webhook update to process through our service
        update = {
          "message" => {
            "text" => message.text,
            "chat" => { "id" => message.chat.id },
            "from" => {
              "id" => message.from.id,
              "username" => message.from.username,
              "first_name" => message.from.first_name
            }
          }
        }

        # Process through our TelegramBotService
        begin
          service = TelegramBotService.new
          service.process_webhook(update)
        rescue => e
          puts "Error processing message: #{e.message}"
          Rails.logger.error "Error processing message: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end

      end
    end
  end
rescue => e
  puts "Telegram bot polling error: #{e.message}"
  Rails.logger.error "Telegram bot polling error: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
  sleep 5
  retry
end
