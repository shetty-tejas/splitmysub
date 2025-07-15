# SplitMySub Deployment Guide with Kamal

This guide covers deploying SplitMySub using [Kamal](https://kamal-deploy.org/), a modern deployment tool for containerized applications.

## Prerequisites

### 1. Server Requirements
- Linux server (Ubuntu 20.04+ recommended)
- Docker installed on the server
- SSH access with sudo privileges

### 2. Local Requirements
- Ruby 3.4.4
- Node.js 20+
- Docker (for local testing)
- Git

### 3. Domain and SSL
- Domain name pointing to your server
- DNS A record configured

## Initial Setup

### 1. Configure Your Server

Update `config/deploy.yml` with your actual server details:

```yaml
servers:
  web:
    - your-server-ip-address  # Replace with actual IP

proxy:
  ssl: true
  host: your-domain.com      # Replace with actual domain
```

### 2. Container Registry Configuration

**GitHub Container Registry (Default - FREE for public repositories)**

The application is pre-configured to use GitHub Container Registry:

```yaml
registry:
  server: ghcr.io
  username: ashwin47
  password:
    - GITHUB_TOKEN
```

**Alternative Options:**

#### Option A: Docker Hub
```yaml
registry:
  username: your-dockerhub-username
  password:
    - DOCKER_HUB_TOKEN
```

#### Option B: DigitalOcean Container Registry
```yaml
registry:
  server: registry.digitalocean.com
  username: your-do-username
  password:
    - DOCKER_REGISTRY_TOKEN
```

### 3. Configure Environment Variables

Set up your environment variables in `.kamal/secrets`. **All secret variables must be configured for production deployment:**

```bash
# GitHub token for container registry (automatic in GitHub Actions)
export GITHUB_TOKEN="your-github-personal-access-token"

# Rails master key (from config/master.key)
export RAILS_MASTER_KEY="$(cat config/master.key)"

# REQUIRED: Admin access password
export ADMIN_PASSWORD="your-secure-admin-password"

# REQUIRED: Email configuration (choose one)
# Option 1: Resend API (recommended)
export RESEND_API_KEY="your-resend-api-key"

# Option 2: SMTP Configuration
export SMTP_USERNAME="your-smtp-username"
export SMTP_PASSWORD="your-smtp-password"

# OPTIONAL: Cloudflare Turnstile (for CAPTCHA protection)
export CLOUDFLARE_TURNSTILE_SITE_KEY="your-turnstile-site-key"
export CLOUDFLARE_TURNSTILE_SECRET_KEY="your-turnstile-secret-key"
```

**Note:** When deploying via GitHub Actions, the `GITHUB_TOKEN` is automatically provided - no manual configuration needed!

### 4. Image Name Configuration

The application is pre-configured to use GitHub Container Registry:

```yaml
image: ghcr.io/ashwin47/splitmysub
```

**For alternative registries:**

```yaml
# Docker Hub
image: your-dockerhub-username/splitmysub

# DigitalOcean
image: registry.digitalocean.com/your-registry/splitmysub
```

## Environment Variables Reference

### Required Variables (Must be set in `.kamal/secrets`)

| Variable | Description | Example |
|----------|-------------|---------|
| `RAILS_MASTER_KEY` | Rails encryption key | `your-32-char-key` |
| `ADMIN_PASSWORD` | Admin interface password | `secure-admin-password` |
| `RESEND_API_KEY` | Resend email service API key | `re_xxxxx` |
| `SMTP_USERNAME` | SMTP email username | `your-email@gmail.com` |
| `SMTP_PASSWORD` | SMTP email password | `your-app-password` |

### Optional Variables (Can be set in `.kamal/secrets`)

| Variable | Description | Default |
|----------|-------------|---------|
| `CLOUDFLARE_TURNSTILE_SITE_KEY` | Cloudflare Turnstile site key | Test key |
| `CLOUDFLARE_TURNSTILE_SECRET_KEY` | Cloudflare Turnstile secret key | Test secret |

### Application Configuration (Set in `config/deploy.yml`)

The following environment variables are configured in the `env.clear` section:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `RAILS_ENV` | Rails environment | `production` | Yes |
| `APP_HOST` | Your application domain | `localhost` | Yes |
| `APP_PROTOCOL` | Protocol (http/https) | `https` | Yes |
| `SOLID_QUEUE_IN_PUMA` | Run background jobs in Puma | `true` | Yes |
| `VITE_RUBY_HOST` | Vite server host | `0.0.0.0` | Yes |
| `VITE_RUBY_PORT` | Vite server port | `3036` | Yes |

### Performance Tuning Variables (Optional)

| Variable | Description | Default | Notes |
|----------|-------------|---------|-------|
| `WEB_CONCURRENCY` | Number of Puma workers | `1` | Increase for multi-core servers |
| `JOB_CONCURRENCY` | Background job processes | `1` | Increase for heavy job processing |
| `RAILS_MAX_THREADS` | Max threads per worker | `3` | Adjust based on server resources |
| `RAILS_LOG_LEVEL` | Logging level | `info` | Use `debug` for troubleshooting |

### Email Configuration Variables (Optional SMTP Settings)

| Variable | Description | Default |
|----------|-------------|---------|
| `SMTP_ADDRESS` | SMTP server address | `smtp.gmail.com` |
| `SMTP_PORT` | SMTP server port | `587` |
| `SMTP_DOMAIN` | SMTP domain | Same as `APP_HOST` |
| `SMTP_AUTHENTICATION` | SMTP authentication method | `plain` |
| `SMTP_ENABLE_STARTTLS_AUTO` | Enable STARTTLS | `true` |
| `SMTP_OPENSSL_VERIFY_MODE` | SSL verification mode | `peer` |

## Deployment Commands

### GitHub Actions Deployment (Recommended)

The repository is configured with GitHub Actions for automatic deployment:

1. **Push to main branch** triggers automatic deployment
2. **GitHub Container Registry** authentication is handled automatically
3. **No manual deployment commands** needed

### Manual Deployment

For manual deployment from your local machine:

#### First-Time Deployment

1. **Setup the server:**
   ```bash
   bin/kamal setup
   ```

2. **Deploy the application:**
   ```bash
   bin/kamal deploy
   ```

#### Regular Deployments

```bash
bin/kamal deploy
```

### Useful Commands

```bash
# Check application status
bin/kamal app details

# View logs
bin/kamal logs

# Access Rails console
bin/kamal console

# Run database migrations
bin/kamal migrate

# Seed the database
bin/kamal seed

# Access shell
bin/kamal shell

# Rollback to previous version
bin/kamal rollback

# Remove application (careful!)
bin/kamal remove
```

## Email Configuration

### Option 1: Resend (Recommended)

1. **Sign up for Resend** at [resend.com](https://resend.com)
2. **Get your API key** from the dashboard
3. **Add to secrets:**
   ```bash
   export RESEND_API_KEY="re_your_api_key"
   ```

### Option 2: SMTP Configuration

Popular SMTP providers:

#### Gmail
```bash
export SMTP_USERNAME="your-email@gmail.com"
export SMTP_PASSWORD="your-app-password"  # Use App Password, not regular password
```

#### Postmark
```bash
export SMTP_USERNAME="your-postmark-token"
export SMTP_PASSWORD="your-postmark-token"
```

Add to `config/deploy.yml`:
```yaml
env:
  clear:
    SMTP_ADDRESS: smtp.postmarkapp.com
    SMTP_PORT: 587
```

#### SendGrid
```bash
export SMTP_USERNAME="apikey"
export SMTP_PASSWORD="your-sendgrid-api-key"
```

Add to `config/deploy.yml`:
```yaml
env:
  clear:
    SMTP_ADDRESS: smtp.sendgrid.net
    SMTP_PORT: 587
```

## Security Configuration

### Admin Access

The admin interface is protected by HTTP Basic Authentication:
- **Username:** `superadmin`
- **Password:** Set via `ADMIN_PASSWORD` environment variable

### Cloudflare Turnstile (Optional)

For CAPTCHA protection on authentication forms:

1. **Get Cloudflare Turnstile keys** from [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. **Add to secrets:**
   ```bash
   export CLOUDFLARE_TURNSTILE_SITE_KEY="your-site-key"
   export CLOUDFLARE_TURNSTILE_SECRET_KEY="your-secret-key"
   ```

**Note:** The application works without Turnstile (uses test keys by default).

## SSL and Domain Configuration

### Automatic SSL with Let's Encrypt

Kamal automatically handles SSL certificates via Let's Encrypt when you configure:

```yaml
proxy:
  ssl: true
  host: your-domain.com
```

### Cloudflare Integration

If using Cloudflare:
1. **Set encryption mode** to "Full" in SSL/TLS settings
2. **Configure proxy settings** in `config/deploy.yml`

## Database Management

### SQLite (Default)

SplitMySub uses SQLite with multiple databases for different purposes:

```yaml
volumes:
  - "splitmysub_storage:/rails/storage"    # File uploads
  - "splitmysub_db:/rails/db"             # All SQLite databases
```

**Database Files:**
- `production.sqlite3` - Main application data
- `production_cache.sqlite3` - Cache data
- `production_queue.sqlite3` - Background jobs
- `production_cable.sqlite3` - WebSocket connections
- `production_errors.sqlite3` - Error tracking

### Database Commands

```bash
# Access database console
bin/kamal app exec --interactive --reuse "bin/rails dbconsole"

# Run migrations
bin/kamal app exec --reuse "bin/rails db:migrate"

# Create database backup
bin/kamal app exec --reuse "bin/rails db:backup"
```

## Monitoring and Maintenance

### Health Checks

Kamal monitors the application via `/up` endpoint:

```yaml
proxy:
  healthcheck:
    path: /up
    port: 3000
    max_attempts: 10
    interval: 3
```

### Log Management

Logs are configured with rotation to prevent disk space issues:

```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
```

### Backup Strategy

**SQLite Database Backup:**
```bash
# Create backup
docker run --rm -v splitmysub_db:/source -v $(pwd):/backup alpine tar czf /backup/db-backup-$(date +%Y%m%d).tar.gz -C /source .

# Restore backup
docker run --rm -v splitmysub_db:/target -v $(pwd):/backup alpine tar xzf /backup/db-backup-YYYYMMDD.tar.gz -C /target
```

**Storage Backup:**
```bash
# Backup uploaded files
docker run --rm -v splitmysub_storage:/source -v $(pwd):/backup alpine tar czf /backup/storage-backup-$(date +%Y%m%d).tar.gz -C /source .
```

### Monitoring

**Built-in Error Tracking:**
- Errors are tracked in `production_errors.sqlite3`
- Access via `/admin/solid_errors` (requires admin authentication)

**Log Monitoring:**
```bash
# Real-time logs
bin/kamal logs -f

# Application-specific logs
bin/kamal logs --since 1h
```

## Troubleshooting

### Common Issues

1. **Build failures:**
   ```bash
   # Check build logs
   bin/kamal build logs
   
   # Rebuild from scratch
   bin/kamal build --no-cache
   ```

2. **Deployment failures:**
   ```bash
   # Check application logs
   bin/kamal logs
   
   # Check container status
   bin/kamal app details
   ```

3. **Email delivery issues:**
   ```bash
   # Test email configuration
   bin/kamal console
   # In Rails console:
   ActionMailer::Base.mail(to: "test@example.com", subject: "Test", body: "Test").deliver_now
   ```

4. **SSL issues:**
   ```bash
   # Check proxy status
   bin/kamal proxy logs
   
   # Restart proxy
   bin/kamal proxy restart
   ```

5. **Database issues:**
   ```bash
   # Check database connectivity
   bin/kamal app exec --interactive --reuse "bin/rails dbconsole"
   
   # Run migrations manually
   bin/kamal migrate
   ```

6. **Admin access issues:**
   ```bash
   # Verify admin password is set
   bin/kamal app exec --reuse "printenv ADMIN_PASSWORD"
   ```

### Debug Mode

Enable debug logging by adding to `config/deploy.yml`:

```yaml
env:
  clear:
    RAILS_LOG_LEVEL: debug
```

### Emergency Procedures

**Application Not Responding:**
```bash
# Check container status
bin/kamal app details

# Restart application
bin/kamal app restart

# Check recent logs
bin/kamal logs --since 30m
```

**Database Corruption:**
```bash
# Check database integrity
bin/kamal app exec --reuse "bin/rails runner 'puts ActiveRecord::Base.connection.execute(\"PRAGMA integrity_check\").first'"

# Restore from backup if needed
# (See backup section above)
```

## Security Considerations

1. **Keep secrets secure:** Never commit `.kamal/secrets` or `config/master.key`
2. **Use strong passwords:** For admin access and email accounts
3. **Regular updates:** Keep Docker images and dependencies updated
4. **Firewall configuration:** Only expose necessary ports (80, 443, 22)
5. **SSH key authentication:** Disable password authentication
6. **Rate limiting:** Built-in via Rails 8 native rate limiting (configured automatically)
7. **Security headers:** Automatically configured (HSTS, CSP, etc.)

## Performance Optimization

1. **Multi-stage builds:** Already configured in Dockerfile
2. **Asset precompilation:** Handled during build process
3. **Container limits:** Configure in `config/deploy.yml`
4. **Database optimization:** Use connection pooling and proper indexing

## Scaling

### Horizontal Scaling

Add more servers to `config/deploy.yml`:

```yaml
servers:
  web:
    - server1.your-domain.com
    - server2.your-domain.com
```

### Load Balancing

Use a load balancer in front of multiple servers or configure Kamal proxy for multiple hosts.

## Support Resources

- [Kamal Documentation](https://kamal-deploy.org/)
- [Kamal GitHub Repository](https://github.com/basecamp/kamal)
- [Rails Deployment Guide](https://guides.rubyonrails.org/deployment.html) 
- [Docker Best Practices](https://docs.docker.com/develop/best-practices/)
- [SSL/TLS Configuration](https://ssl-config.mozilla.org/)
- [Production Rails Security](https://guides.rubyonrails.org/security.html)

### Getting Help

- **Application Logs**: `bin/kamal logs`
- **System Logs**: SSH to server and check `/var/log/`
- **Health Status**: Monitor `/up` endpoint
- **Admin Interface**: `/admin` (requires authentication)
- **Error Tracking**: `/admin/solid_errors` (requires authentication)
- **Community**: Rails and Kamal community forums
- **Professional Support**: Consider professional Rails hosting services

---

**Quick Deployment Checklist:**

- [ ] Server with Docker installed
- [ ] Domain pointing to server
- [ ] Container registry configured
- [ ] All required environment variables set in `.kamal/secrets`
- [ ] `config/deploy.yml` updated with your details
- [ ] Email delivery configured (Resend or SMTP)
- [ ] Admin password set
- [ ] Run `bin/kamal setup` and `bin/kamal deploy`