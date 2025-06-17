# Reminder System Setup Guide

## Overview

The reminder system automatically sends payment reminders to project members based on configurable schedules and escalation levels. It includes:

- Automated email reminders with escalation levels
- Unsubscribe functionality for legal compliance
- Payment confirmation emails
- Background job processing with Solid Queue
- Time zone awareness
- Bounce handling and delivery tracking

## Components

### 1. Core Services
- `ReminderService` - Main service for processing reminders
- `ReminderMailer` - Handles email generation and sending
- `ReminderMailerJob` - Background job for sending individual reminders
- `DailyReminderProcessorJob` - Daily job to process all reminders
- `PaymentConfirmationJob` - Sends payment confirmation emails

### 2. Models
- `ReminderSchedule` - Configures reminder timing and escalation levels
- Enhanced `Payment` model with confirmation email callbacks
- Enhanced `User` model with unsubscribe preferences

### 3. Controllers
- `UnsubscribeController` - Handles unsubscribe functionality
- Enhanced `ProjectsController` with reminder preview and settings

## Setup Instructions

### 1. Database Setup
The reminder system uses existing models. Ensure your database is migrated:

```bash
rails db:migrate
```

### 2. Background Job Processing
The system uses Solid Queue (already configured in Gemfile). Start the background job processor:

```bash
# In production, this should be managed by your process manager (systemd, etc.)
rails solid_queue:start
```

### 3. Daily Reminder Processing
Set up a cron job to run daily reminder processing. Add to your crontab:

```bash
# Run daily at 9:00 AM
0 9 * * * cd /path/to/your/app && rails reminders:process
```

Or use whenever gem for more sophisticated scheduling:

```ruby
# In config/schedule.rb (if using whenever gem)
every 1.day, at: '9:00 am' do
  rake 'reminders:process'
end
```

### 4. Email Configuration
Ensure your email settings are configured in `config/environments/production.rb`:

```ruby
config.action_mailer.smtp_settings = {
  address: 'smtp.gmail.com',
  port: 587,
  domain: 'yourdomain.com',
  user_name: ENV['GMAIL_USERNAME'],
  password: ENV['GMAIL_PASSWORD'],
  authentication: 'plain',
  enable_starttls_auto: true
}

config.action_mailer.default_url_options = { host: 'yourdomain.com' }
```

## Usage

### 1. Configure Reminder Schedules
For each project, configure reminder schedules with different escalation levels:

```ruby
# Example: Create reminder schedules for a project
project = Project.find(1)

# Gentle reminder 7 days before due date
project.reminder_schedules.create!(
  days_before: 7,
  escalation_level: 1
)

# Standard reminder 3 days before due date
project.reminder_schedules.create!(
  days_before: 3,
  escalation_level: 2
)

# Urgent reminder 1 day before due date
project.reminder_schedules.create!(
  days_before: 1,
  escalation_level: 3
)
```

### 2. Escalation Levels
- **Level 1**: Gentle reminder (friendly tone)
- **Level 2**: Standard reminder (more direct)
- **Level 3**: Urgent reminder (urgent tone with warnings)
- **Level 4**: Final notice (strong warnings)
- **Level 5**: Critical alert (final warning before action)

### 3. Manual Processing
You can manually trigger reminder processing:

```bash
# Process all reminders
rake reminders:process

# Test reminders for a specific project
rake reminders:test[PROJECT_ID]

# View reminder statistics
rake reminders:stats
```

### 4. Preview Reminders
Project creators can preview reminder emails:

```
GET /projects/:id/preview_reminder?escalation_level=1
```

### 5. Unsubscribe Functionality
Users can unsubscribe from reminders using the link in emails. The system:
- Tracks unsubscribe preferences per project
- Respects unsubscribe status when sending reminders
- Provides a user-friendly unsubscribe interface

## Monitoring and Maintenance

### 1. Log Monitoring
Monitor Rails logs for reminder processing:

```bash
tail -f log/production.log | grep -i reminder
```

### 2. Job Queue Monitoring
Monitor Solid Queue for failed jobs:

```bash
rails console
SolidQueue::Job.failed.count
```

### 3. Email Delivery Monitoring
Monitor email delivery rates and bounces through your email provider's dashboard.

### 4. Database Cleanup
Periodically clean up old reminder logs and expired tokens (if implemented).

## Troubleshooting

### Common Issues

1. **Reminders not sending**
   - Check background job processor is running
   - Verify email configuration
   - Check for failed jobs in Solid Queue

2. **Duplicate reminders**
   - Ensure cron job runs only once daily
   - Check for multiple background job processors

3. **Unsubscribe links not working**
   - Verify routes are configured correctly
   - Check token generation and decoding

### Testing

Test the reminder system in development:

```bash
# Start letter opener for email preview
rails server

# In another terminal, trigger reminders
rake reminders:process

# View emails at http://localhost:3000/letter_opener
```

## Security Considerations

1. **Unsubscribe tokens**: Use secure token generation in production
2. **Email headers**: Set appropriate email headers for deliverability
3. **Rate limiting**: Consider rate limiting for email sending
4. **Data privacy**: Ensure compliance with email marketing regulations

## Performance Optimization

1. **Batch processing**: Process reminders in batches for large user bases
2. **Database indexing**: Ensure proper indexes on date and status fields
3. **Email queuing**: Use background jobs for all email sending
4. **Caching**: Cache frequently accessed project and user data

## Future Enhancements

Potential improvements to consider:

1. **SMS reminders**: Add SMS notification support
2. **Reminder templates**: Allow custom email templates per project
3. **Advanced scheduling**: Support for custom reminder schedules
4. **Analytics**: Track reminder effectiveness and payment rates
5. **A/B testing**: Test different reminder strategies
6. **Integration**: Connect with payment processors for automatic confirmation 