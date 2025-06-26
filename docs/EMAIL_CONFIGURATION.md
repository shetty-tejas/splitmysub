# Email Configuration

This application supports two email delivery methods:

1. **Resend API** (Recommended for production)
2. **SMTP** (Fallback option)

## Resend Integration

### Setup

1. **Install the gem** (already added to Gemfile):
   ```ruby
   gem "resend"
   ```

2. **Get your API key**:
   - Sign up at [Resend](https://resend.com)
   - Create an API key in your [Resend Dashboard](https://resend.com/api-keys)

3. **Configure environment variables**:
   ```bash
   # Required for Resend
   RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxx
   
   # Optional: Use Resend in development (otherwise uses letter_opener)
   USE_RESEND_IN_DEV=true
   ```

### Verified Domains

Before sending emails in production, you need to verify your domain in Resend:

1. Go to [Resend Domains](https://resend.com/domains)
2. Add your domain
3. Add the required DNS records
4. Wait for verification

### Usage in Mailers

The configuration is automatic. Your existing mailers will work without changes:

```ruby
class UserMailer < ApplicationMailer
  default from: 'Acme <noreply@yourdomain.com>' # Must be verified domain
  
  def welcome_email
    @user = params[:user]
    mail(to: @user.email, subject: 'Welcome!')
  end
end
```

### Environment-specific Behavior

- **Production**: Uses Resend if `RESEND_API_KEY` is set, falls back to SMTP
- **Development**: Uses `letter_opener` by default, or Resend if `USE_RESEND_IN_DEV=true`
- **Test**: Uses the default test delivery method

## SMTP Fallback

If Resend is not configured, the application will fall back to SMTP using these environment variables:

```bash
SMTP_USERNAME=your-smtp-username
SMTP_PASSWORD=your-smtp-password
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=yourdomain.com
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer
```

## Testing

### Development Testing

1. **With letter_opener** (default):
   - Emails open in your browser automatically
   - No actual emails are sent

2. **With Resend**:
   - Set `USE_RESEND_IN_DEV=true` and `RESEND_API_KEY`
   - Real emails will be sent

### Production Testing

Use the Rails console to test email delivery:

```ruby
# Test with a simple email
UserMailer.with(user: User.first).welcome_email.deliver_now!

# Check the response
result = UserMailer.with(user: User.first).welcome_email.deliver_now!
puts result # Should show Resend response with email ID
```

## Monitoring

Resend provides excellent email analytics:

- **Dashboard**: View email delivery status, opens, clicks
- **Webhooks**: Set up webhooks for delivery events
- **Logs**: Detailed delivery logs with error information

## Benefits of Resend over SMTP

1. **Better Deliverability**: Higher inbox placement rates
2. **Analytics**: Built-in email tracking and analytics
3. **Reliability**: More reliable than traditional SMTP
4. **Developer Experience**: Better error handling and debugging
5. **Webhooks**: Real-time delivery status updates
6. **Templates**: Rich HTML email templates support

## Troubleshooting

### Common Issues

1. **"Domain not verified"**: Verify your domain in Resend dashboard
2. **API key errors**: Check that `RESEND_API_KEY` is correctly set
3. **Rate limits**: Resend has generous rate limits, but check your plan

### Debug Mode

Enable debug logging in development:

```ruby
# In config/environments/development.rb
config.log_level = :debug
```

This will show detailed email delivery information in your logs. 