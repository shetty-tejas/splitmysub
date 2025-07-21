class TelegramController < ApplicationController
  skip_before_action :verify_authenticity_token
  allow_unauthenticated_access

  def webhook
    begin
      update = JSON.parse(request.body.read)
      Rails.logger.info "Received Telegram webhook: #{update.inspect}"

      # Process the update through the bot service
      TelegramBotService.new.process_webhook(update)

      head :ok
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON in Telegram webhook: #{e.message}"
      head :bad_request
    rescue => e
      Rails.logger.error "Error processing Telegram webhook: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      head :internal_server_error
    end
  end
end
