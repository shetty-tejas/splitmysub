#!/usr/bin/env ruby

require 'bundler/setup'
require_relative 'config/environment'

puts "🤖 TELEGRAM INTEGRATION DEVELOPMENT TESTER"
puts "=" * 50

# Check if bot is configured
token_present = Rails.application.credentials.telegram_bot_token.present?
puts "✅ Bot token configured: #{token_present}"

if !token_present
  puts "❌ No bot token found. Add one to Rails credentials."
  exit 1
end

# Test 1: Create/find test user
puts "\n1️⃣ Setting up test user..."
user = User.find_or_create_by(email_address: 'telegram_dev_test@example.com') do |u|
  u.first_name = 'Dev'
  u.last_name = 'Tester'
end
puts "✅ User: #{user.full_name} (#{user.email_address})"

# Test 2: Generate verification token
puts "\n2️⃣ Generating verification token..."
token = user.generate_telegram_verification_token
puts "✅ Token: #{token}"
puts "✅ Expires: #{user.telegram_verification_token_expires_at}"
puts "📱 To test manually, send this to your bot:"
puts "   /start #{token}"

# Test 3: Test TelegramBotService initialization
puts "\n3️⃣ Testing TelegramBotService..."
service = TelegramBotService.new
puts "✅ Service initialized"

# Test 4: Simulate webhook processing
puts "\n4️⃣ Testing webhook processing..."
fake_chat_id = 555555555
fake_update = {
  'update_id' => 12345,
  'message' => {
    'message_id' => 1,
    'chat' => { 'id' => fake_chat_id },
    'from' => { 'id' => fake_chat_id, 'username' => 'dev_tester' },
    'text' => '/start'
  }
}

puts "📨 Processing fake /start command..."
service.process_webhook(fake_update)
puts "✅ Webhook processing completed"

# Test 5: Link account simulation
puts "\n5️⃣ Simulating account linking..."
user.update!(
  telegram_user_id: fake_chat_id.to_s,
  telegram_username: 'dev_tester',
  telegram_verification_token: nil,
  telegram_verification_token_expires_at: nil
)
puts "✅ Account linked: #{user.telegram_linked?}"
puts "✅ Username: #{user.telegram_username}"
puts "✅ Notifications: #{user.telegram_notifications_enabled?}"

# Test 6: Test notification sending (will fail with fake chat_id, but shows the flow)
puts "\n6️⃣ Testing notification system..."
begin
  result = service.send_notification(
    user: user,
    message_type: 'test',
    content: 'Test notification from development'
  )
  if result
    puts "✅ Notification sent successfully"
  else
    puts "⚠️  Notification failed (expected with fake chat_id)"
  end
rescue => e
  puts "⚠️  Notification error (expected): #{e.message}"
end

puts "\n🎉 DEVELOPMENT TESTING COMPLETE!"
puts "\n" + "=" * 50
puts "NEXT STEPS FOR REAL TESTING:"
puts "1. Visit http://localhost:3000/profile/edit"
puts "2. Generate a real token"
puts "3. Send /start <token> to your actual bot"
puts "4. Verify the account links successfully"
puts "=" * 50
