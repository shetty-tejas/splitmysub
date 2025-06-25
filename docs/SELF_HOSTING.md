# SplitMySub Self-Hosting Guide

Welcome to SplitMySub! This guide will help you self-host your own instance of SplitMySub.

## Quick Start

### 1. Environment Variables

Create a `.env` file or set these environment variables:

```bash
# Required - App Configuration
APP_HOST=your-domain.com
APP_PROTOCOL=https
RAILS_MASTER_KEY=your-rails-master-key

# Required - SMTP Email Configuration
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-smtp-password
```

### 2. Deploy with Docker

```bash
# Clone the repository
git clone https://github.com/yourusername/splitmysub.git
cd splitmysub

# Build and run
docker-compose up -d
```

## Email Configuration (SMTP)

SplitMySub uses SMTP for sending emails. Choose one of the following providers:

### 🟢 Gmail (Easiest for personal use)

Perfect for small instances and testing.

```bash
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-16-character-app-password  # Not your regular password!
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
```

**Setup Steps:**
1. Enable 2-Factor Authentication on your Gmail account
2. Go to [Google Account Settings](https://myaccount.google.com/) → Security → 2-Step Verification → App passwords
3. Generate an app password for "Mail"
4. Use your Gmail address and the 16-character app password

### 🟡 SendGrid (Recommended for production)

Great for production use with high email volume.

```bash
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
```

**Setup Steps:**
1. Sign up at [SendGrid](https://sendgrid.com/)
2. Create an API key with "Mail Send" permissions
3. Use `apikey` as username and your API key as password

### 🟡 Mailgun

Another excellent production option.

```bash
SMTP_USERNAME=your-mailgun-smtp-username
SMTP_PASSWORD=your-mailgun-smtp-password
SMTP_ADDRESS=smtp.mailgun.org
SMTP_PORT=587
```

### 🟡 AWS SES

If you're already using AWS infrastructure.

```bash
SMTP_USERNAME=your-ses-smtp-username
SMTP_PASSWORD=your-ses-smtp-password
SMTP_ADDRESS=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
```

### 🔧 Custom SMTP Server

For any other SMTP provider:

```bash
SMTP_USERNAME=your-smtp-username
SMTP_PASSWORD=your-smtp-password
SMTP_ADDRESS=your-smtp-server.com
SMTP_PORT=587
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
```

## Advanced Configuration

### Optional Environment Variables

```bash
# Email settings
SMTP_DOMAIN=your-domain.com                    # Default: uses APP_HOST
SMTP_AUTHENTICATION=plain                      # Default: plain
SMTP_ENABLE_STARTTLS_AUTO=true                # Default: true
SMTP_OPENSSL_VERIFY_MODE=peer                 # Default: peer

# App settings
DATABASE_URL=postgresql://user:pass@host/db   # For external database
ASSET_HOST=https://cdn.your-domain.com        # For CDN
RAILS_LOG_LEVEL=info                          # Default: info
```

## Deployment Options

### Option 1: Docker Compose (Recommended)

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    environment:
      - APP_HOST=your-domain.com
      - SMTP_USERNAME=your-email@gmail.com
      - SMTP_PASSWORD=your-app-password
      - RAILS_MASTER_KEY=your-master-key
    ports:
      - "80:80"
    volumes:
      - splitmysub_storage:/rails/storage
      - splitmysub_db:/rails/db

volumes:
  splitmysub_storage:
  splitmysub_db:
```

### Option 2: Kamal Deployment

```bash
# Configure config/deploy.yml with your server details
bin/kamal setup
bin/kamal deploy
```

### Option 3: Manual Deployment

```bash
# Standard Rails deployment
bundle install
RAILS_ENV=production bin/rails assets:precompile
RAILS_ENV=production bin/rails db:migrate
RAILS_ENV=production bin/rails server
```

## Testing Email Configuration

After deployment, test your email setup:

```bash
# Via Docker
docker exec -it splitmysub-app bin/rails runner "TestMailer.test_email('your-email@example.com').deliver_now"

# Via Kamal
bin/kamal runner "TestMailer.test_email('your-email@example.com').deliver_now"

# Direct Rails
bin/rails runner "TestMailer.test_email('your-email@example.com').deliver_now"
```

## Troubleshooting

### Common SMTP Issues

1. **Authentication Failed**
   - Gmail: Make sure you're using an App Password, not your regular password
   - Check username/password are correct
   - Verify 2FA is enabled (for Gmail)

2. **Connection Timeout**
   - Check SMTP_ADDRESS and SMTP_PORT
   - Verify firewall settings allow outbound SMTP connections
   - Try SMTP_PORT=465 with SSL instead of STARTTLS

3. **SSL/TLS Issues**
   - Set `SMTP_OPENSSL_VERIFY_MODE=none` for development (not recommended for production)
   - Check your SMTP provider's SSL/TLS requirements

### Getting Help

- Check logs: `docker logs splitmysub-app` or `bin/kamal logs`
- Test SMTP connection manually using telnet or openssl
- Consult your SMTP provider's documentation

## Security Considerations

- Use strong passwords and API keys
- Enable SSL/TLS for SMTP connections
- Keep your Rails master key secure
- Regularly update dependencies
- Consider using a firewall
- Use HTTPS in production

## Why SMTP?

We chose SMTP because it's:
- ✅ **Universal** - Works with any email provider
- ✅ **Flexible** - You choose your preferred service
- ✅ **Simple** - Just username/password configuration
- ✅ **Cost-effective** - Free options available
- ✅ **Private** - No vendor lock-in or API dependencies

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[Your chosen license] 