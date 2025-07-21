# Telegram Webhook Development Setup

## Overview
This guide explains how to set up Telegram webhooks for local development, replacing the polling method with a more production-like webhook approach.

## Prerequisites
- ngrok installed: `brew install ngrok`
- Telegram bot token configured in Rails credentials
- Rails development server running

## Setup Process

### 1. Start Rails Server
```bash
bin/rails s
```
The server should be running on `http://localhost:3000`

### 2. Start ngrok Tunnel
In a separate terminal:
```bash
ngrok http 3000
```

You'll see output like:
```
Session Status                online
Account                       your-account (Plan: Free)
Version                       3.x.x
Region                        United States (us)
Forwarding                    https://abc123def.ngrok.io -> http://localhost:3000
```

Copy the HTTPS URL (e.g., `https://abc123def.ngrok.io`)

### 3. Update Environment Configuration
Create or update your `.env` file in the project root:
```bash
# Telegram Webhook Configuration
TELEGRAM_WEBHOOK_URL=https://abc123def.ngrok.io/telegram/webhook
TELEGRAM_USE_WEBHOOKS=true

# Your other environment variables...
APP_HOST=localhost
APP_PROTOCOL=http
# etc...
```

### 4. Set up the Webhook
Once the rake tasks are implemented:
```bash
bin/rails telegram:setup_webhook
```

### 5. Test the Integration
Send a message to your bot (e.g., `/help`) and check the Rails logs to confirm webhooks are working:
```bash
tail -f log/development.log
```

You should see logs like:
```
Telegram webhook received: ...
Processing webhook update: ...
Webhook processed in 0.123s
```

## Troubleshooting

### Check Webhook Status
```bash
bin/rails telegram:webhook_info
```

### Reset Webhook
If having issues:
```bash
bin/rails telegram:reset_webhook
```

### Common Issues

1. **ngrok session expired**: Free ngrok sessions expire after 8 hours. Restart ngrok and update your `.env` file.

2. **Webhook not receiving messages**: 
   - Verify the ngrok URL is accessible: `curl https://your-ngrok-url.ngrok.io/up`
   - Check that Rails server is running
   - Ensure webhook URL in `.env` matches ngrok URL exactly

3. **SSL certificate errors**: Always use the HTTPS URL from ngrok, not HTTP

4. **Rate limiting**: Telegram limits webhook calls. If testing heavily, use polling temporarily.

## Development Workflow

1. Start Rails: `bin/rails s`
2. Start ngrok: `ngrok http 3000` 
3. Update `.env` with new ngrok URL
4. Setup webhook: `bin/rails telegram:setup_webhook`
5. Test by messaging your bot
6. Check logs: `tail -f log/development.log`

## Switching Back to Polling (Temporary)

If you need to temporarily switch back to polling:

1. Comment out webhook environment variables in `.env`:
   ```bash
   # TELEGRAM_WEBHOOK_URL=https://abc123def.ngrok.io/telegram/webhook
   # TELEGRAM_USE_WEBHOOKS=true
   ```

2. Uncomment the telegram line in `Procfile.dev`:
   ```
   telegram: ruby lib/telegram_polling.rb
   ```

3. Restart your development server: `bin/dev`

## Production Notes

In production, webhooks are automatically configured using the `base_url` from Rails credentials. No manual tunnel setup is needed. 