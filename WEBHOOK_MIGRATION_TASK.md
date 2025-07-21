# Task: Migrate Telegram Bot from Polling to Webhooks ✅ COMPLETED

## Status: **MIGRATION SUCCESSFUL** 
> **Completed**: July 21, 2025  
> **Result**: Full webhook implementation with comprehensive tooling and documentation

## Overview
Currently, the SplitMySub application uses Telegram polling for development and webhooks for production. This task involves fully switching to webhooks for all environments to improve performance, reduce server resource usage, and enable better scalability.

## Current State Analysis

### Polling Implementation (Current)
- **Development**: Uses `lib/telegram_polling.rb` with continuous polling
- **Process**: Runs as separate process via `Procfile.dev` 
- **Method**: Calls `TelegramBotService#process_message(message)`
- **Resource Usage**: Continuous CPU usage, persistent connections
- **Reliability**: Single point of failure, requires process management

### Webhook Implementation (Partial)
- **Production**: Configured but only for production environment
- **Route**: `POST /telegram/webhook` → `TelegramController#webhook`
- **Method**: Calls `TelegramBotService#process_webhook(update)`
- **Resource Usage**: Event-driven, no persistent connections
- **Reliability**: Stateless, scales horizontally

## Migration Plan

### Phase 1: Development Webhook Setup

#### 1.1 Local Development Tunnel
**Requirement**: Expose local Rails server to internet for webhook delivery

**Options**:
- **ngrok** (Recommended for development)
- **LocalTunnel** 
- **Cloudflare Tunnel**
- **SSH tunnel to VPS**

**Implementation**:
```bash
# Install ngrok
brew install ngrok

# Start tunnel (in separate terminal)
ngrok http 3000

# Use the HTTPS URL for webhook registration
```

#### 1.2 Environment Configuration
**File**: `config/initializers/telegram.rb`

**Changes needed**:
```ruby
# Current logic only sets webhook in production
if Rails.env.production?
  # Set webhook...
end

# New logic - set webhook in development too
if Rails.env.production? || Rails.env.development?
  webhook_url = if Rails.env.development?
    # Use ngrok URL or environment variable
    ENV.fetch('TELEGRAM_WEBHOOK_URL', 'https://your-ngrok-id.ngrok.io/telegram/webhook')
  else
    "#{Rails.application.credentials.base_url}/telegram/webhook"
  end
  
  # Set webhook...
end
```

#### 1.3 Environment Variables
**File**: `.env.example` and local `.env`

**Add**:
```bash
# Telegram Webhook Configuration
TELEGRAM_WEBHOOK_URL=https://your-ngrok-id.ngrok.io/telegram/webhook
TELEGRAM_USE_WEBHOOKS=true
```

### Phase 2: Remove Polling Infrastructure

#### 2.1 Update Procfile.dev
**File**: `Procfile.dev`

**Current**:
```
vite: bin/vite dev
web: bin/rails s
telegram: ruby lib/telegram_polling.rb
```

**New**:
```
vite: bin/vite dev
web: bin/rails s
# telegram: ruby lib/telegram_polling.rb  # REMOVED
```

#### 2.2 Deprecate Polling Script
**Actions**:
1. Move `lib/telegram_polling.rb` to `lib/archived/telegram_polling.rb`
2. Add deprecation warning to the file
3. Update documentation to reflect webhook-only approach

#### 2.3 Clean Up TelegramBotService
**File**: `app/services/telegram_bot_service.rb`

**Optional**: Remove `process_message` method if no longer needed:
```ruby
# This method can be removed after migration
def process_message(message)
  # Convert polling message to webhook format...
end
```

### Phase 3: Enhanced Webhook Implementation

#### 3.1 Webhook Security
**File**: `app/controllers/telegram_controller.rb`

**Add webhook verification**:
```ruby
class TelegramController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_telegram_webhook, only: :webhook

  def webhook
    # existing implementation
  end

  private

  def verify_telegram_webhook
    # Verify webhook authenticity using secret token
    secret_token = Rails.application.credentials.telegram_webhook_secret
    if secret_token.present?
      provided_token = request.headers['X-Telegram-Bot-Api-Secret-Token']
      unless ActiveSupport::SecurityUtils.secure_compare(secret_token, provided_token.to_s)
        head :unauthorized
        return
      end
    end
  end
end
```

#### 3.2 Webhook Registration with Secret
**File**: `config/initializers/telegram.rb`

**Enhanced webhook setup**:
```ruby
# Generate or retrieve webhook secret
webhook_secret = Rails.application.credentials.telegram_webhook_secret

response = Rails.application.config.telegram_bot.api.set_webhook(
  url: webhook_url,
  allowed_updates: ["message", "callback_query"],
  secret_token: webhook_secret,
  max_connections: 100,
  drop_pending_updates: true
)
```

#### 3.3 Webhook Management Commands
**File**: `lib/tasks/telegram.rake`

**Create new rake tasks**:
```ruby
namespace :telegram do
  desc "Set up Telegram webhook"
  task setup_webhook: :environment do
    # Implementation to set webhook
  end

  desc "Remove Telegram webhook"
  task remove_webhook: :environment do
    # Implementation to delete webhook
  end

  desc "Get webhook info"
  task webhook_info: :environment do
    # Implementation to get webhook status
  end

  desc "Reset webhook (remove and setup)"
  task reset_webhook: :environment do
    # Implementation to reset webhook
  end
end
```

### Phase 4: Infrastructure Updates

#### 4.1 Docker Configuration
**File**: `docker-compose.dev.yml`

**Update to remove polling dependency**:
```yaml
services:
  web:
    # existing configuration
    environment:
      - RAILS_ENV=development
      - TELEGRAM_USE_WEBHOOKS=true
      - TELEGRAM_WEBHOOK_URL=https://your-ngrok-id.ngrok.io/telegram/webhook
    # Remove any telegram polling service
```

#### 4.2 Production Deployment
**File**: `config/deploy.yml`

**Add webhook-specific environment variables**:
```yaml
env:
  secret:
    - TELEGRAM_WEBHOOK_SECRET
  clear:
    TELEGRAM_USE_WEBHOOKS: true
```

#### 4.3 Health Check Enhancement
**File**: `app/controllers/telegram_controller.rb`

**Add health check endpoint**:
```ruby
def health_check
  # Verify webhook is properly configured
  if Rails.application.credentials.telegram_bot_token.present?
    render json: { status: "ok", mode: "webhook" }
  else
    render json: { status: "error", message: "Bot token not configured" }, status: :service_unavailable
  end
end
```

**File**: `config/routes.rb`

**Add route**:
```ruby
get "telegram/health" => "telegram#health_check"
```

### Phase 5: Development Workflow Updates

#### 5.1 Developer Setup Instructions
**File**: `docs/TELEGRAM_WEBHOOK_SETUP.md` (New file)

**Content**:
```markdown
# Telegram Webhook Development Setup

## Prerequisites
- ngrok installed: `brew install ngrok`
- Telegram bot token configured in Rails credentials

## Setup Process

1. Start Rails server:
   ```bash
   bin/rails s
   ```

2. Start ngrok tunnel (separate terminal):
   ```bash
   ngrok http 3000
   ```

3. Copy the HTTPS URL from ngrok (e.g., `https://abc123.ngrok.io`)

4. Update your `.env` file:
   ```bash
   TELEGRAM_WEBHOOK_URL=https://abc123.ngrok.io/telegram/webhook
   ```

5. Set up the webhook:
   ```bash
   bin/rails telegram:setup_webhook
   ```

6. Test by sending a message to your bot

## Troubleshooting
- Check webhook status: `bin/rails telegram:webhook_info`
- Reset webhook: `bin/rails telegram:reset_webhook`
- Check logs: `tail -f log/development.log`
```

#### 5.2 Update Main Documentation
**Files to update**:
- `README.md` - Update development setup instructions
- `CLAUDE.md` - Remove polling references, add webhook info
- `docs/DEPLOYMENT.md` - Add webhook configuration steps
- `docs/SYSTEM_ARCHITECTURE.md` - Update Telegram integration section

### Phase 6: Testing and Validation

#### 6.1 Update Test Suite
**File**: `test/controllers/telegram_controller_test.rb`

**Add comprehensive webhook tests**:
```ruby
class TelegramControllerTest < ActionDispatch::IntegrationTest
  test "webhook processes valid telegram update" do
    post telegram_webhook_path, params: valid_telegram_update.to_json,
         headers: { 'Content-Type' => 'application/json' }
    assert_response :ok
  end

  test "webhook rejects invalid JSON" do
    post telegram_webhook_path, params: "invalid json",
         headers: { 'Content-Type' => 'application/json' }
    assert_response :bad_request
  end

  test "webhook requires secret token when configured" do
    # Test with and without secret token
  end

  private

  def valid_telegram_update
    {
      update_id: 123,
      message: {
        message_id: 456,
        chat: { id: 789 },
        from: { id: 789, username: "testuser" },
        text: "/help"
      }
    }
  end
end
```

#### 6.2 Integration Tests
**File**: `test/integration/telegram_webhook_test.rb` (New file)

**Test complete webhook flow**:
```ruby
class TelegramWebhookTest < ActionDispatch::IntegrationTest
  test "complete webhook flow from telegram message to response" do
    # Test user authentication, command processing, response sending
  end
end
```

#### 6.3 Load Testing
**Considerations**:
- Test webhook endpoint under load
- Verify webhook reliability vs polling
- Monitor response times and error rates

### Phase 7: Monitoring and Observability

#### 7.1 Webhook Metrics
**Add monitoring for**:
- Webhook request volume
- Processing time per webhook
- Error rates and types
- Failed webhook deliveries

#### 7.2 Alerting
**Set up alerts for**:
- Webhook endpoint downtime
- High error rates
- Telegram API rate limiting
- Certificate expiration (for HTTPS)

#### 7.3 Logging Enhancement
**File**: `app/controllers/telegram_controller.rb`

**Improve logging**:
```ruby
def webhook
  Rails.logger.info "Telegram webhook received: #{request.headers['X-Telegram-Delivery-Time']}"
  
  update = JSON.parse(request.body.read)
  
  # Log processing start
  processing_start = Time.current
  
  TelegramBotService.new.process_webhook(update)
  
  # Log processing duration
  duration = Time.current - processing_start
  Rails.logger.info "Webhook processed in #{duration.round(3)}s"
  
  head :ok
rescue => e
  Rails.logger.error "Webhook processing failed: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
  head :internal_server_error
end
```

## Implementation Timeline

### Week 1: Infrastructure Setup
- [ ] Set up ngrok/tunnel solution
- [ ] Update environment configuration
- [ ] Test webhook endpoint locally

### Week 2: Code Changes
- [ ] Update TelegramBotService
- [ ] Enhance webhook security
- [ ] Create management rake tasks
- [ ] Update documentation

### Week 3: Testing and Validation
- [ ] Write comprehensive test suite
- [ ] Perform integration testing
- [ ] Load test webhook endpoint
- [ ] Validate against production environment

### Week 4: Deployment and Cleanup
- [ ] Deploy webhook changes to production
- [ ] Remove polling infrastructure
- [ ] Update monitoring and alerting
- [ ] Final documentation updates

## Rollback Plan

In case of issues, the rollback process:

1. **Immediate**: Re-enable polling by uncommenting Procfile.dev line
2. **Quick**: Revert initializer to only use webhooks in production
3. **Full**: Restore `lib/telegram_polling.rb` from archived version

## Success Criteria

- [ ] Webhooks working in all environments (dev, staging, production)
- [ ] No message loss during transition
- [ ] Reduced server resource usage
- [ ] Improved response times
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Monitoring in place

## Benefits After Migration

1. **Performance**: No persistent connections, reduced CPU usage
2. **Scalability**: Horizontal scaling without coordination issues
3. **Reliability**: No single process to fail, built-in retry mechanisms
4. **Development**: Consistent behavior across all environments
5. **Monitoring**: Better observability into message processing

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Webhook endpoint downtime | Message loss | Implement health checks, monitoring |
| HTTPS certificate issues | Webhook failures | Automated certificate renewal |
| Rate limiting | Service degradation | Implement backoff, monitoring |
| Network connectivity | Regional failures | Multiple webhook URLs, fallback |
| Development complexity | Slower development | Good documentation, tooling |

## Notes

- Telegram webhooks have a 10-second timeout for responses
- Maximum 100 concurrent connections per bot
- Webhooks require HTTPS (not HTTP)
- Bot API supports up to 100 webhook requests per second
- Failed webhooks are retried by Telegram with exponential backoff 