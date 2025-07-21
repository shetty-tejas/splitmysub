# Reminder System Setup Guide

## Overview

The reminder system automatically sends payment reminders to project members based on configurable schedules and escalation levels. It includes:

- Automated email reminders with escalation levels
- Telegram notifications for users with linked accounts
- Unsubscribe functionality for legal compliance
- Payment confirmation emails
- Background job processing with SolidQueue
- Time zone awareness
- Bounce handling and delivery tracking

## Components

### 1. Core Services
- `ReminderService` - Main service for processing reminders
- `ReminderMailer` - Handles email generation and sending
- `ReminderMailerJob` - Background job for sending individual reminders
- `DailyReminderProcessorJob` - Daily job to process all reminders
- `TelegramNotificationJob` - Sends Telegram notifications for reminders
- `PaymentConfirmationJob` - Sends payment confirmation emails

### 2. Models
- `ReminderSchedule` - Configures reminder timing and escalation levels
- Enhanced `Payment` model with confirmation email callbacks
- Enhanced `User` model with unsubscribe preferences and Telegram integration
- `TelegramMessage` - Tracks Telegram notification delivery

### 3. Controllers
- `UnsubscribeController` - Handles unsubscribe functionality
- Enhanced `ProjectsController` with reminder preview and settings

## Setup Instructions

### 1. Database Setup
The reminder system uses existing models. Ensure your SQLite database is migrated:

```bash
rails db:migrate
```

### 2. Background Job Processing
The system uses SolidQueue (already configured in Gemfile). Background jobs are processed automatically in production via the `SOLID_QUEUE_IN_PUMA=true` environment variable. For development:

```bash
# Jobs are processed in-process with Puma in development
# No additional setup needed
```

### 3. Daily Reminder Processing
The application supports multiple ways to schedule daily reminder processing:

#### Option 1: Manual Cron Job (Recommended)
Set up a cron job to run daily reminder processing. Add to your crontab:

```bash
# Run daily at 9:00 AM
0 9 * * * cd /path/to/your/app && bin/rails "reminders:process"
```

Or use whenever gem for more sophisticated scheduling:

```ruby
# In config/schedule.rb (if using whenever gem)
every 1.day, at: '9:00 am' do
  rake 'reminders:process'
end
```

#### Option 2: Background Job Scheduling
Alternatively, you can use the DailyReminderProcessorJob directly:

```bash
# Schedule the job to run daily at 9 AM
0 9 * * * cd /path/to/your/app && bin/rails runner "DailyReminderProcessorJob.perform_later"
```

#### Option 3: SolidQueue Recurring Tasks (Advanced)
SolidQueue supports recurring tasks, but this is not currently configured. You can enable it by adding to `config/recurring.yml`:

```yaml
production:
  daily_reminders:
    class: DailyReminderProcessorJob
    schedule: "0 9 * * *"  # Daily at 9 AM
    queue: default

  billing_cycle_generation:
    class: BillingCycleGeneratorJob
    schedule: "0 6 * * *"  # Daily at 6 AM
    queue: default
    args: [3]  # 3 months ahead

  old_cycle_archiving:
    class: BillingCycleArchiverJob
    schedule: "0 3 * * 0"  # Weekly on Sunday at 3 AM
    queue: default
    args: [6]  # Archive cycles older than 6 months
```

**Note**: If using SolidQueue recurring tasks, you don't need the manual cron jobs. The recurring tasks will be managed automatically by SolidQueue.

### 4. Email and Telegram Configuration
Ensure your email settings are configured. The app supports Resend API (recommended) or SMTP:

```bash
# Environment variables for email
RESEND_API_KEY=your-resend-api-key
# OR
SMTP_USERNAME=your-smtp-username
SMTP_PASSWORD=your-smtp-password
```

For Telegram notifications, configure the bot token in Rails credentials:

```yaml
# config/credentials.yml.enc
telegram_bot_token: your-telegram-bot-token
```

**Note**: The Telegram bot uses webhooks for real-time message processing. For development setup and webhook configuration, see [docs/TELEGRAM_WEBHOOKS.md](TELEGRAM_WEBHOOKS.md).

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
bin/rails "reminders:process"

# Test email configuration
bin/rails "email:test[your-email@example.com]"

# Clean up expired invitations
bin/rails "invitations:cleanup"

# Show reminder statistics
bin/rails "reminders:stats"

# Test reminders for specific project
bin/rails "reminders:test[PROJECT_ID]"

# Schedule daily reminder processing job
bin/rails "reminders:schedule_daily"
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
Monitor SolidQueue for failed jobs:

```bash
rails console
SolidQueue::Job.failed.count
```

### 3. Email and Telegram Delivery Monitoring
- Monitor email delivery rates and bounces through your email provider's dashboard
- Check Telegram message delivery status in the `telegram_messages` table
- Monitor Telegram webhook delivery status in application logs

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
# Start development server with letter opener for email preview
bin/dev

# In another terminal, trigger reminders
bin/rails "reminders:process"

# View emails at http://localhost:3000/letter_opener
```

## Security Considerations

1. **Unsubscribe tokens**: Use secure token generation in production
2. **Email headers**: Set appropriate email headers for deliverability
3. **Rate limiting**: Consider rate limiting for email sending
4. **Data privacy**: Ensure compliance with email marketing regulations

## Performance Optimization

1. **Batch processing**: Process reminders in batches for large user bases
2. **SQLite indexing**: Ensure proper indexes on date and status fields
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
7. **Enhanced Telegram**: Rich media support, interactive buttons
8. **Reminder logs**: Database tracking of sent reminders for better monitoring 