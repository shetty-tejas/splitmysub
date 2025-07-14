Rails.application.config.after_initialize do
  # Configure Telegram bot if token is available
  begin
    # Skip Telegram integration in test environment to avoid credential issues
    if Rails.env.test?
      Rails.logger.info "Skipping Telegram integration in test environment"
      return
    end

    token = Rails.application.credentials.telegram_bot_token

    if token.present?
      Rails.logger.info "Initializing Telegram bot integration"

      # Initialize the global bot instance
      Rails.application.config.telegram_bot = Telegram::Bot::Client.new(token)

      # Set up webhook in production
      if Rails.env.production?
        webhook_url = "#{Rails.application.credentials.base_url}/telegram/webhook"

        begin
          response = Rails.application.config.telegram_bot.api.set_webhook(
            url: webhook_url,
            allowed_updates: [ "message", "callback_query" ]
          )

          if response["ok"]
            Rails.logger.info "Telegram webhook set successfully: #{webhook_url}"
          else
            Rails.logger.error "Failed to set Telegram webhook: #{response['description']}"
          end
        rescue => e
          Rails.logger.error "Error setting up Telegram webhook: #{e.message}"
        end
      else
        Rails.logger.info "Telegram bot initialized for development (no webhook)"
      end
    else
      Rails.logger.warn "Telegram bot token not configured - Telegram integration disabled"
    end
  rescue => e
    Rails.logger.error "Error initializing Telegram bot: #{e.message}"
    Rails.logger.warn "Telegram integration disabled due to initialization error"
  end
end
