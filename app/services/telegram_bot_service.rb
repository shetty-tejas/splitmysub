# Skip if telegram-bot-ruby gem is not available
begin
  require "telegram/bot"
rescue LoadError
  # Define a dummy class if the gem is not available
  class TelegramBotService
    def initialize
      Rails.logger.warn "TelegramBotService initialized but telegram-bot-ruby gem not available"
    end

    def send_message(*args)
      Rails.logger.warn "Telegram message sending disabled - gem not available"
      nil
    end

    def send_notification(*args)
      Rails.logger.warn "Telegram notification disabled - gem not available"
      false
    end

    def process_webhook(*args)
      Rails.logger.warn "Telegram webhook processing disabled - gem not available"
    end
  end
  return
end

class TelegramBotService
  def initialize
    # Defer bot initialization until needed to avoid credential access during class loading
    @bot = nil
    @initialized = false
  end

  def send_message(chat_id:, text:, parse_mode: "HTML", reply_markup: nil)
    return nil unless bot

    response = bot.api.send_message(
      chat_id: chat_id,
      text: text,
      parse_mode: parse_mode,
      reply_markup: reply_markup
    )

    if response["ok"]
      Rails.logger.info "Telegram message sent successfully to #{chat_id}"
      response["result"]
    else
      Rails.logger.error "Failed to send Telegram message: #{response['description']}"
      nil
    end
  rescue => e
    Rails.logger.error "Telegram API error: #{e.message}"
    nil
  end

  def send_notification(user:, message_type:, content:)
    return false unless user.telegram_user_id.present? && user.telegram_notifications_enabled?

    telegram_message = TelegramMessage.create!(
      user: user,
      message_type: message_type,
      content: content,
      status: "pending"
    )

    result = send_message(
      chat_id: user.telegram_user_id,
      text: content
    )

    if result
      telegram_message.update!(
        telegram_message_id: result["message_id"],
        status: "sent",
        sent_at: Time.current
      )
      true
    else
      telegram_message.update!(status: "failed")
      false
    end
  end

  def process_webhook(update)
    Rails.logger.info "Processing webhook update: #{update.inspect}"
    message = update["message"]
    if message && message["text"]
      process_text_message(update)
    else
      Rails.logger.info "Received unsupported message type: #{update.inspect}"
    end
  end

  def process_message(message)
    Rails.logger.info "Processing polling message: #{message.inspect}"

    # Convert polling message to webhook format for compatibility with existing code
    if message.text
      update = {
        "message" => {
          "chat" => { "id" => message.chat.id },
          "from" => {
            "id" => message.from.id,
            "username" => message.from.username
          },
          "text" => message.text
        }
      }
      process_text_message(update)
    else
      Rails.logger.info "Received non-text message type from polling: #{message.inspect}"
    end
  end

  private

  def process_text_message(update)
    message = update["message"]
    chat_id = message["chat"]["id"]
    text = message["text"]
    user_info = message["from"]

    Rails.logger.info "Processing message from #{chat_id}: #{text}"

    # Find user by telegram_user_id
    user = User.find_by(telegram_user_id: chat_id.to_s)
    Rails.logger.info "Found user: #{user ? user.id : 'none'} for chat_id: #{chat_id}"

    if text.start_with?("/start")
      Rails.logger.info "Handling start command"
      handle_start_command(chat_id, text, user_info)
    elsif user.nil?
      Rails.logger.info "Handling unauthenticated user"
      handle_unauthenticated_user(chat_id)
    else
      Rails.logger.info "Handling authenticated command for user #{user.id}"
      handle_authenticated_command(user, text, chat_id)
    end
  end

  def handle_start_command(chat_id, text, user_info)
    # Extract verification token if present
    token = text.split(" ")[1] if text.split(" ").length > 1

    if token
      user = User.find_by(telegram_verification_token: token)

      if user && user.telegram_verification_token_expires_at > Time.current
        # Link the account
        user.update!(
          telegram_user_id: chat_id.to_s,
          telegram_username: user_info["username"],
          telegram_verification_token: nil,
          telegram_verification_token_expires_at: nil
        )

        send_message(
          chat_id: chat_id,
          text: "🎉 Account linked successfully! Welcome to SplitMySub, #{user.first_name}!\n\nYou can now receive payment reminders and manage your subscriptions through this bot.\n\nType /help to see available commands."
        )
      else
        send_message(
          chat_id: chat_id,
          text: "❌ Invalid or expired verification token. Please generate a new one from your profile settings."
        )
      end
    else
      send_message(
        chat_id: chat_id,
        text: "👋 Welcome to SplitMySub!\n\nTo link your account, please go to your profile settings and generate a verification code.\n\nOnce you have the code, type:\n<code>/start YOUR_CODE</code>",
        parse_mode: "HTML"
      )
    end
  end

  def handle_unauthenticated_user(chat_id)
    send_message(
      chat_id: chat_id,
      text: "🔐 Please link your SplitMySub account first.\n\nGo to your profile settings and generate a verification code, then type:\n<code>/start YOUR_CODE</code>",
      parse_mode: "HTML"
    )
  end

  def handle_authenticated_command(user, text, chat_id)
    case text
    when "/help"
      handle_help_command(chat_id)
    when "/status"
      handle_status_command(user, chat_id)
    when "/payments"
      handle_payments_command(user, chat_id)
    when "/settings"
      handle_settings_command(user, chat_id)
    when /^\/pay/
      handle_pay_command(user, text, chat_id)
    else
      send_message(
        chat_id: chat_id,
        text: "❓ Unknown command. Type /help to see available commands."
      )
    end
  end

  def handle_help_command(chat_id)
    help_text = <<~TEXT
      🤖 <b>SplitMySub Bot Commands</b>

      /status - Show your current payment status
      /payments - List all pending payments
      /pay [project] - Mark a payment as completed
      /settings - Manage notification preferences
      /help - Show this help message

      💡 You can also receive automatic payment reminders and updates through this bot!
    TEXT

    send_message(chat_id: chat_id, text: help_text)
  end

  def handle_status_command(user, chat_id)
    pending_payments = user.payments.joins(:billing_cycle)
                          .where(billing_cycles: { archived: false })
                          .where(status: "pending")
                          .count

    projects_count = user.all_projects.count

    status_text = <<~TEXT
      📊 <b>Your Payment Status</b>

      🔴 Pending payments: #{pending_payments}
      📁 Active projects: #{projects_count}

      #{pending_payments > 0 ? "Use /payments to see details." : "✅ All payments up to date!"}
    TEXT

    send_message(chat_id: chat_id, text: status_text)
  end

  def handle_payments_command(user, chat_id)
    Rails.logger.info "Handling payments command for user #{user.id}"

    pending_payments = user.payments.includes(:billing_cycle, billing_cycle: :project)
                          .joins(:billing_cycle)
                          .where(billing_cycles: { archived: false })
                          .where(status: "pending")
                          .limit(10)

    Rails.logger.info "Found #{pending_payments.count} pending payments for user #{user.id}"

    if pending_payments.empty?
      send_message(
        chat_id: chat_id,
        text: "✅ No pending payments! You're all caught up."
      )
      return
    end

    payments_text = "<b>💳 Pending Payments</b>\n\n"

    pending_payments.each_with_index do |payment, index|
      project = payment.billing_cycle.project
      due_date = payment.billing_cycle.due_date
      days_until_due = (due_date.to_date - Date.current).to_i

      status_emoji = days_until_due < 0 ? "🔴" : days_until_due <= 3 ? "🟡" : "🟢"

      payments_text += <<~PAYMENT
        #{status_emoji} <b>#{project.name}</b>
        Amount: #{user.format_currency(project.cost_per_member, project.currency)}
        Due: #{due_date.strftime('%B %d, %Y')}
        #{days_until_due < 0 ? "⚠️ #{-days_until_due} days overdue" : "📅 #{days_until_due} days remaining"}

        Use: <code>/pay #{project.name.downcase.gsub(/\s+/, '_')}</code>

      PAYMENT
    end

    send_message(chat_id: chat_id, text: payments_text)
  end

  def handle_settings_command(user, chat_id)
    settings_text = <<~TEXT
      ⚙️ <b>Notification Settings</b>

      Telegram notifications: #{user.telegram_notifications_enabled? ? "🟢 Enabled" : "🔴 Disabled"}

      To change your notification preferences, please visit your profile settings in the web app.
    TEXT

    send_message(chat_id: chat_id, text: settings_text)
  end

  def handle_pay_command(user, text, chat_id)
    # Extract project identifier from command
    project_identifier = text.split(" ")[1]

    if project_identifier.blank?
      send_message(
        chat_id: chat_id,
        text: "❓ Please specify a project. Example: <code>/pay netflix</code>\n\nUse /payments to see available projects.",
        parse_mode: "HTML"
      )
      return
    end

    # Find project by name (case-insensitive, underscore-friendly)
    project = user.all_projects.find do |p|
      p.name.downcase.gsub(/\s+/, "_") == project_identifier.downcase ||
      p.name.downcase.include?(project_identifier.downcase)
    end

    unless project
      send_message(
        chat_id: chat_id,
        text: "❌ Project not found. Use /payments to see available projects."
      )
      return
    end

    # Find pending payment for this project
    pending_payment = user.payments.joins(:billing_cycle)
                         .where(billing_cycles: { project: project, archived: false })
                         .where(status: "pending")
                         .first

    unless pending_payment
      send_message(
        chat_id: chat_id,
        text: "✅ No pending payment found for #{project.name}."
      )
      return
    end

    # Mark payment as confirmed
    pending_payment.update!(
      status: "confirmed",
      confirmation_date: Date.current,
      confirmation_notes: "Confirmed via Telegram bot"
    )

    send_message(
      chat_id: chat_id,
      text: "✅ Payment confirmed for <b>#{project.name}</b>!\n\nAmount: #{user.format_currency(project.cost_per_member, project.currency)}\nConfirmed at: #{Time.current.strftime('%B %d, %Y at %I:%M %p')}",
      parse_mode: "HTML"
    )

    # Log the confirmation
    Rails.logger.info "Payment confirmed via Telegram by user #{user.id} for project #{project.id}"
  end

  private

  def bot
    return @bot if @initialized

    @initialized = true
    token = Rails.application.credentials.telegram_bot_token
    @bot = token.present? ? Telegram::Bot::Client.new(token) : nil
    @bot
  end
end
