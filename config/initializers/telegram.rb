# Skip Telegram integration in test environment
unless Rails.env.test?
  Rails.application.config.after_initialize do
    # Configure Telegram bot if token is available
    begin
      # Skip if telegram-bot-ruby gem is not available
      unless defined?(Telegram::Bot)
        Rails.logger.warn "Telegram bot gem not available - Telegram integration disabled"
        return
      end

      token = Rails.application.credentials.telegram_bot_token

      if token.present?
        Rails.logger.info "Initializing Telegram bot integration"

        # Initialize the global bot instance
        Rails.application.config.telegram_bot = Telegram::Bot::Client.new(token)

        # Determine webhook URL based on environment
        webhook_url = if Rails.env.development?
          ENV.fetch("TELEGRAM_WEBHOOK_URL", nil)
        elsif Rails.env.production?
          "#{Rails.application.credentials.base_url}/telegram/webhook"
        else
          nil
        end

        # Use webhooks if webhook URL is available, otherwise log info
        if webhook_url.present?
          begin
              # Enhanced webhook setup with additional parameters
              webhook_params = {
              url: webhook_url,
                allowed_updates: [ "message", "callback_query" ],
                max_connections: 100,
                drop_pending_updates: true
              }

              # Add secret token if available (for enhanced security)
              webhook_secret = Rails.application.credentials.telegram_webhook_secret
              webhook_params[:secret_token] = webhook_secret if webhook_secret.present?

              response = Rails.application.config.telegram_bot.api.set_webhook(webhook_params)

              # Handle both boolean and hash responses from Telegram API
              success = response == true || (response.is_a?(Hash) && response["ok"])
              
              if success
                Rails.logger.info "Telegram webhook set successfully: #{webhook_url}"
                Rails.logger.info "Webhook mode: #{Rails.env.production? ? 'production' : 'development'}"
              else
                error_msg = response.is_a?(Hash) ? response["description"] : "Unknown error"
                Rails.logger.error "Failed to set Telegram webhook: #{error_msg}"
              end
          rescue => e
            Rails.logger.error "Error setting up Telegram webhook: #{e.message}"
          end
        else
          Rails.logger.info "Telegram bot initialized without webhook (TELEGRAM_WEBHOOK_URL not configured for development)"
        end
      else
        Rails.logger.warn "Telegram bot token not configured - Telegram integration disabled"
      end
    rescue => e
      Rails.logger.error "Error initializing Telegram bot: #{e.message}"
      Rails.logger.warn "Telegram integration disabled due to initialization error"
    end
  end
else
  Rails.logger.info "Skipping Telegram integration (test environment)"
end
