# SolidErrors Integration

This document describes the SolidErrors integration in the SplitSub application.

## Overview

[SolidErrors](https://github.com/fractaledmind/solid_errors) is a database-backed, app-internal exception tracker for Rails applications. It provides a simple way to track and monitor errors that occur in your application without requiring external services.

## Features

- **Database-backed error tracking**: All errors are stored in your application's database
- **Web dashboard**: View and manage errors through a clean web interface
- **Admin-only access**: Integrated with the existing admin authentication system
- **Automatic error capturing**: Errors are automatically captured when they occur
- **Error resolution**: Mark errors as resolved directly from the dashboard
- **Auto-cleanup**: Resolved errors are automatically deleted after 30 days

## Access

The SolidErrors dashboard is available at `/admin/errors` and is restricted to admin users only. Access is controlled by the existing `Admin::BaseController` authentication system.

### Admin Access Requirements

- Development/Test environments: All authenticated users have admin access
- Production: Users with email addresses matching `admin@*` or `*@splitmysub.*` patterns have admin access

## Database Schema

SolidErrors uses two tables in the main database:

- `solid_errors`: Stores unique error types with fingerprints
- `solid_errors_occurrences`: Stores individual occurrences of each error type

## Configuration

The SolidErrors configuration is located in `config/initializers/solid_errors.rb`:

```ruby
Rails.application.configure do
  # Use Admin::BaseController for authentication
  config.solid_errors.base_controller_class = "Admin::BaseController"
  
  # Auto-destroy resolved errors after 30 days
  config.solid_errors.destroy_after = 30.days
end
```

## Usage

1. **Viewing Errors**: Navigate to `/admin/errors` when logged in as an admin
2. **Error Details**: Click on any error to view detailed information including:
   - Exception class and message
   - Full backtrace
   - Context information
   - All occurrences with timestamps
3. **Resolving Errors**: Mark errors as resolved once they've been fixed
4. **Automatic Cleanup**: Resolved errors are automatically deleted after 30 days

## Testing

To test that SolidErrors is working correctly:

```bash
# Generate a test error
rails runner "raise 'Test error for verification'"

# Check that the error was captured
rails runner "puts SolidErrors::Error.count"
```

## Integration with Error Handling

SolidErrors automatically captures:
- Unhandled exceptions in controllers
- Background job failures
- Any errors reported through Rails' error reporting system

The errors are captured with full context including:
- Request parameters (when applicable)
- User information (when available)
- Environment details
- Full stack traces

## Production Considerations

- Errors are stored in the main database, so monitor database size if you have high error volumes
- Consider setting up email notifications for critical errors (currently disabled)
- The 30-day auto-cleanup helps prevent the error tables from growing too large
- Admin access is restricted in production environments

## Migration History

- `20250626102245_create_solid_errors_tables.rb`: Creates the initial SolidErrors schema 