# SplitMySub Deployment Guide with Kamal

This guide covers deploying SplitMySub using [Kamal](https://kamal-deploy.org/), a modern deployment tool for containerized applications.

## Prerequisites

### 1. Server Requirements
- Linux server (Ubuntu 20.04+ recommended)
- Docker installed on the server
- SSH access with sudo privileges
- At least 2GB RAM and 20GB disk space

### 2. Local Requirements
- Ruby 3.4.4+
- Node.js 20.18.1+
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
  host: your-domain.com      # Replace with actual domain
```

### 2. Set Up Container Registry

Choose one of these options:

#### Option A: Docker Hub
```yaml
registry:
  username: your-dockerhub-username
  password:
    - KAMAL_REGISTRY_PASSWORD
```

#### Option B: GitHub Container Registry
```yaml
registry:
  server: ghcr.io
  username: your-github-username
  password:
    - KAMAL_REGISTRY_PASSWORD
```

#### Option C: DigitalOcean Container Registry
```yaml
registry:
  server: registry.digitalocean.com
  username: your-do-username
  password:
    - KAMAL_REGISTRY_PASSWORD
```

### 3. Configure Environment Variables

Set up your environment variables in `.kamal/secrets`:

```bash
# Registry password (Docker Hub token, GitHub token, etc.)
export KAMAL_REGISTRY_PASSWORD="your-registry-token"

# Rails master key (from config/master.key)
export RAILS_MASTER_KEY="$(cat config/master.key)"
```

### 4. Update Image Name

In `config/deploy.yml`, update the image name:

```yaml
image: your-registry-username/splitmysub
```

## Deployment Commands

### First-Time Deployment

1. **Setup the server:**
   ```bash
   bin/kamal setup
   ```

2. **Deploy the application:**
   ```bash
   bin/kamal deploy
   ```

### Regular Deployments

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

## Environment Configuration

### Production Environment Variables

The following environment variables are configured in `config/deploy.yml`:

- `RAILS_ENV=production`
- `SOLID_QUEUE_IN_PUMA=true` - Runs background jobs in Puma
- `VITE_RUBY_HOST=0.0.0.0` - Vite configuration for production
- `VITE_RUBY_PORT=3036` - Vite port configuration

### Optional Configuration

You can add these to the `env.clear` section in `config/deploy.yml`:

```yaml
env:
  clear:
    # Performance tuning
    WEB_CONCURRENCY: 2
    JOB_CONCURRENCY: 3
    
    # External database (if not using SQLite)
    # DB_HOST: your-db-host
    # DB_NAME: splitmysub_production
    
    # Asset CDN
    # ASSET_HOST: https://cdn.your-domain.com
    
    # Email configuration
    # SMTP_HOST: smtp.your-provider.com
    # SMTP_PORT: 587
    
    # Logging
    # RAILS_LOG_LEVEL: info
```

### Secret Environment Variables

Add sensitive variables to `.kamal/secrets`:

```bash
# Database credentials (if using external DB)
# DB_PASSWORD=$YOUR_DB_PASSWORD

# Email credentials
# SMTP_USERNAME=$YOUR_SMTP_USERNAME
# SMTP_PASSWORD=$YOUR_SMTP_PASSWORD

# Third-party API keys
# STRIPE_SECRET_KEY=$YOUR_STRIPE_SECRET_KEY
```

## SSL and Domain Configuration

### Automatic SSL with Let's Encrypt

Kamal automatically handles SSL certificates via Let's Encrypt when you configure:

```yaml
proxy:
  ssl: true
  host: your-domain.com
```

### Custom SSL Certificates

If you have custom certificates, you can configure them in the proxy section.

## Database Management

### SQLite (Default)

SplitMySub uses SQLite by default with persistent volumes:

```yaml
volumes:
  - "splitmysub_storage:/rails/storage"
- "splitmysub_db:/rails/db"
```

### External Database

To use PostgreSQL or MySQL, update `config/deploy.yml`:

```yaml
accessories:
  db:
    image: postgres:15
    host: your-db-server
    port: "127.0.0.1:5432:5432"
    env:
      clear:
        POSTGRES_DB: splitmysub_production
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
```

## Monitoring and Maintenance

### Health Checks

Kamal is configured to check `/up` endpoint:

```yaml
proxy:
  healthcheck:
    path: /up
    port: 3000
    max_attempts: 10
    interval: 3
```

### Log Management

Logs are configured with rotation:

```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
```

### Backup Strategy

For SQLite databases, backup the volume:

```bash
# Create backup
docker run --rm -v splitmysub_db:/source -v $(pwd):/backup alpine tar czf /backup/db-backup-$(date +%Y%m%d).tar.gz -C /source .

# Restore backup
docker run --rm -v splitmysub_db:/target -v $(pwd):/backup alpine tar xzf /backup/db-backup-YYYYMMDD.tar.gz -C /target
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

3. **SSL issues:**
   ```bash
   # Check proxy status
   bin/kamal proxy logs
   
   # Restart proxy
   bin/kamal proxy restart
   ```

4. **Database issues:**
   ```bash
   # Access database console
   bin/kamal dbc
   
   # Run migrations manually
   bin/kamal migrate
   ```

### Debug Mode

Enable debug logging by adding to `config/deploy.yml`:

```yaml
env:
  clear:
    RAILS_LOG_LEVEL: debug
```

## Security Considerations

1. **Keep secrets secure:** Never commit `.kamal/secrets` or `config/master.key`
2. **Use strong passwords:** For registry and database access
3. **Regular updates:** Keep Docker images and dependencies updated
4. **Firewall configuration:** Only expose necessary ports (80, 443, 22)
5. **SSH key authentication:** Disable password authentication

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

## Support

- [Kamal Documentation](https://kamal-deploy.org/)
- [Kamal GitHub Repository](https://github.com/basecamp/kamal)
- [Rails Deployment Guide](https://guides.rubyonrails.org/deployment.html) 